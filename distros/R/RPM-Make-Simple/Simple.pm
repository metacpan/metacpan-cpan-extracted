package RPM::Make::Simple;

use strict;
use warnings;

use RPM::Make;
use File::Copy;
use File::Path;
use Carp;

our $VERSION = '0.03';

# parameter => default
# '' denotes mandatory parameter
my %param_defs = (
    arch => '',
    version => '0.01',
    release => '1',
    name => '',
    build_root => './build',
    temp_build_loc => 'temp_build_loc'
);

sub new {
    my($proto, %params) = @_;
    my $self = {};
    my $class = ref($proto) || $proto;

    bless ($self, $class);

    while(my($param, $val) = each(%param_defs)) {
        if(($val eq '') && (!defined $params{$param})) {
            croak("Undefined mandatory parameter $param");
        }

        if(defined $params{$param}) {
            $self->{$param} = $params{$param};
        }
        else {
            $self->{$param} = $val;
        }
    }

    $self->{requires} = [];

    return($self);
}

my %built_dirs;

# Causes health check nightmares, left here for legacy reasons
sub FilePerms {
    my ($self, %file_perms) = @_;

    while(my($file, $perms) = each(%file_perms)) {
        my $file_build_path = $self->{build_root}."/".$file;

        croak("No such file $file in ".$self->{build_root})
            if(!-e $file_build_path);

        croak("Cannot modify $file in ".$self->{build_root})
            if(!chmod($perms, $file_build_path));
    }
}

sub Clean {
    my($self) = shift;

    rmtree($self->{build_root});
}

sub Files {
    my ($self, %locs) = @_;

    my $err = 0;

    while(my($from, $to) = each(%locs)) {
        if(!-e $from) {
            carp("From file $from does not exist");
            $err++;
            next;
        }
        if(-d $from) {
            carp("From file $from is a directory, won't build");
            $err++;
            next;
        }

        my $new_dir = $to;

        if($to =~ /\/$/) {
            my @to_parts = split(/\//, $from);
            $to .= pop(@to_parts);
        }
        else {
            $new_dir =~ s/\/[^\/]*$//;
        }

        if(!defined $built_dirs{$new_dir}) {
            mkpath([$self->{build_root}."/$new_dir"], 1, 0711);
            $built_dirs{$new_dir} = 1;
        }

        print("$from, $self->{build_root}.\"/$to\"\n");

        copy($from, $self->{build_root}."/$to");
        push(@{$self->{build_files}}, $self->{build_root}."/$to");
    }

    croak("Encountered $err errors, cannot proceed") if($err > 0);
}

sub _check_file {
    my($self, @files) = @_;

    my @missing_file;

    foreach(@files) {
        my $file = $_;

        if(!-e $self->{build_root}."/$file") {
            push(@missing_file, $file);
        }
    }

    return join(', ', @missing_file);
}

sub Doc {
    my($self, @docs) = @_;

    my $missing = $self->_check_file(@docs);

    croak("Document files missing in ".$self->{build_root}.": $missing")
        if($missing);

    $self->{doc} = { map {$_ => 1} @docs };
}

sub Conf {
    my($self, @conf) = @_;

    my $missing = $self->_check_file(@conf);

    croak("Config files missing in ".$self->{build_root}.": $missing")
        if($missing);

    $self->{conf} = { map {$_ => 1} @conf };
}

sub ConfNoReplace {
    my($self, @conf_no_replace) = @_;

    my $missing = $self->_check_file(@conf_no_replace);

    croak("Non-replacable config files missing in ".$self->{build_root}.
          ": $missing") if($missing);

    $self->{confnoreplace} = { map {$_ => 1} @conf_no_replace };
}

sub Requires {
    my ($self, %reqs) = @_;

    while(my($req_pack, $req_ver) = each(%reqs)) {
        my $pre_req = "PreReq: $req_pack";

        # if we have a version defined, use that too
        if(defined $req_ver) {
            $pre_req .= " >= $req_ver";
        }
        push(@{$self->{requires}}, $pre_req);
    }
}

# all of these are mandatory. if the value is '1' then it's case sensitive
my %req_metadata = (
    summary => 0,
    vendor => 0,
    group => 0,
    AutoReqProv => 1
);

my %metadata;

# nightmarishly complicated!
sub MetaData {
    my $self = shift;

    carp("RPM name already defined")
        if(defined $_->{name});

    %metadata = @_;
}

sub Build {
    my($self) = shift;

    $metadata{requires} = $self->{requires};
    $metadata{name} = $self->{name};

    my $bad_meta;
    foreach(keys(%req_metadata)) {
        my $tag = $_;
        $tag = lc($tag) if($req_metadata{$_} ne '1');
        if(!defined $metadata{$tag}) {
            my $msg = "Undefined mandatory metadata tag '$tag'";
            $msg .= ", this tag is case sensitive"
                if($req_metadata{$_} eq '1');

            carp($msg);
            $bad_meta = 1;
        }
    }

    croak("Fatal error, there's some undefined metadata") if($bad_meta);

    eval {
        RPM::Make::execute($self->{name}, $self->{version}, $self->{release},
                           $self->{arch}, $self->{temp_build_loc},
                           $self->{build_root}, $self->{build_files},
                           $self->{doc}, $self->{conf}, $self->{confnoreplace},
                           \%metadata);
    };
    if($@) {
        croak($!);
    }

    return(1);
}

sub DESTROY {
    my($self) = shift;
    rmtree($self->{temp_build_loc})	if($self->{temp_build_loc});
}

1;

__END__

=head1 NAME

RPM::Make::Simple - simple interface to RPM::Make

=head1 SYNOPSIS

  use RPM::Make::Simple;

  # define some important build data
  my $rpm = RPM::Make::Simple->new(name => 'RPM_Name', #mandatory
                                   arch => 'i386', # mandatory
                                   version => '0.01',
                                   release => '1',
                                   build_root => './build',
                                   temp_build_loc => 'temp_build_loc');

  # 'From_File' => 'To_File_or_Dir'
  $rpm->Files('./scripts/some_script.pl' => '/usr/bin/some_script',
              './docs/some_document' => '/usr/man/man3/some_document',
              './config/some_config' => '/etc/some_config',
              './config/keep_config' => '/etc/keep_config');

  # tell RPM::Make this is a document (optional)
  $rpm->Doc('/usr/man/man3/some_document');

  # this is a config file (optional)
  $rpm->Conf('/etc/some_config');

  # config file we don't want to replace if it's there (optional)
  $rpm->ConfNoReplace('/etc/keep_config');

  # Some pre-requisites
  $rpm->Requires('perl(RPM::Make)' => 0.9);

  # Some more metadata, summary, post installation etc.
  $rpm->MetaData('summary' => 'package for blah blah',
                 'description' => 'longer than the summary',
                 'post' => $post_install_script,
                 'AutoReqProv' => 'no',
                 'vendor' => 'Bob Co.',
                 'group' => 'Bob RPMS');

  # build the RPM! woo!
  $rpm->Build();

  # clean up the temporary files
  $rpm->Clean();

=head1 DESCRIPTION

Generates an RPM from a given list of files.

I wrote this as a 'dumb' RPM builder. An understanding of how an RPM is built
(with spec files and whatnot) is desirable before using this. It's basically
a wrapper for RPM::Make where the most important difference is how files are
chosen and organised, using a simple 'from_file => to_file' syntax.

The Files and MetaData methods can be called more than once.

See RPM::Make for more info.

=head1 METHODS

=head2 new

RPM::Make::Simple constructor. Takes the following mandatory parameters (as a hash):

=over 4

=item name

name of the RPM

=item arch

architecture of machine (e.g. i386)

=back

Optional parameters (defaults in brackets):

=over 4

=item  version

version number of package (0.01)

=item release

release number of package (1)

=item build_root

directory the RPMs will be built in (./build)

=item temp_build_loc

directory where the files for the RPM will be copied whilst building (temp_build_loc)

=back

=head2 Files

List of files that will be installed, using a hash you can set the current location of a file and it's installation destination. For example, if I want to install a file called 'bob.pl' from '/home/bob/scripts/bob.pl' to '/usr/local/bin/bob' (notice you can rename the file during this phase) I would do the following:

=over 4

$rpm->Files('/home/bob/scripts/bob.pl' => '/usr/local/bin/bob')

=back

=head2 Doc

List of documents (as an array), such as man pages etc. Files in this list must already have been passed to the 'Files' function and always use the 'to' location.

=head2 Conf

List of config files, again it's an array. Files in this list must already have been passed to the 'Files' function and always use the 'to' location.

=head2 ConfNoReplace

Array of config files that shouldn't be replaced. Files in this list must already have been passed to the 'Files' function and always use the 'to' location.

=head2 Requires

List of requirements as a hash, where the key is the required package and the value is the version. For example, if I want to have a requirement of the package 'tim' verion '6' I would do the following:

=over 4

$rpm->Requires('tim' => '6');

=back

=head2 MetaData

Metadata not covered by the other functions (although you can overwrite here if you know about RPM::Make). Example of a summary being added:

=over 4

$rpm->MetaData('summary' => 'blah blah blah');

=back

It requires the following hash keys as its parameters:

=over 4

   Summary - A short summary of the RPM
   Description - A description of the RPM
   AutoReqProv - Automatic dependency processing, either "yes" or "no"
   Vendor - The RPM vendor
   Group - The name of the RPM group that this RPM is part of

=back

The AutoReqProv is case sensitive, the other parameters aren't.

=head2 Build

Invokes the build, no arguments required. Returns true if it succeeeds.

=head2 Clean

Removes temporary build directories.

=head2 FilePerms

Disused. Method left in for legacy reasons.

=head1 SEE ALSO

RPM::Make, rpmbuild etc.

=head1 BUGS

RPM::Make 0.8 does not support certain RPM features such as post installation
scripts. Althought most features will work fine, it is recommended that you
use version 0.9.

=head1 AUTHOR

Stephen Hardisty, E<lt>moowahaha@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 MessageLabs.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

