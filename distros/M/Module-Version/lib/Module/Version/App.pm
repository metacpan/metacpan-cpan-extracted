package Module::Version::App;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Application implementation for Module::Version

use strict;
use warnings;
use Carp qw< croak >;

use Getopt::Long    qw( :config no_ignore_case );
use Module::Version 'get_version';

our $VERSION = '0.13';

sub new { return bless {}, $_[0] }

sub run {
    my $self    = shift;
    my @modules;

    $self->parse_opts;

    if( $self->{local_lib} and -d  $self->{local_lib} ) {
        require local::lib;
        local::lib->import( $self->{local_lib} );
    }

    $self->{'modules'}
        and push @modules, @{ $self->{'modules'} };

    if ( my $file = $self->{'input'} ) {
        open my $fh, '<', $file
            or croak("Cannot open '$file': $!");

        chomp( my @extra_modules = <$fh> );
        push @modules, @extra_modules;

        close $fh
            or croak("Cannot close '$file': $!");
    }

    if ( $self->{'include'} ) {
        my $include = $self->{'include'};

        ref $include eq 'ARRAY'
            or die "Error: include must be an ARRAY ref\n";

        unshift @INC, @{$include};
    }

    @modules
        or die "Error: no modules to check\n";

    foreach my $module (@modules) {
        my $version = get_version($module);
        if ( !$version ) {
            $self->{'quiet'}
                or warn "Warning: module '$module' does not seem to be installed.\n";

            next;
        }

        $self->{'dev'} or $version =~ s/_(.+)$/$1/xms;

        my $output = $self->{'full'} ? "$module $version\n" : "$version\n";
        print $output;
    }
}

sub parse_opts {
    my $self = shift;

    GetOptions(
        'h|help'       => sub { $self->help },
        'f|full!'      => \$self->{'full'},
        'i|input=s'    => \$self->{'input'},
        'l|local-lib=s'=> \$self->{'local_lib'},
        'I|include=s@' => \$self->{'include'},
        'd|dev!'       => \$self->{'dev'},
        'q|quiet!'     => \$self->{'quiet'},
        '<>'           => sub { $self->process(@_) },
    ) or $self->error('could not parse options');
}

sub process {
    my ( $self, @args ) = @_;

    # force stringify Getopt::Long input
    push @{ $self->{'modules'} }, "$_" for @args;
}

sub help {
    my $self = shift;

    print << "_END_HEREDOC";
$0 [ OPTIONS ] Module Module Module...

Provide a module's version, comfortably.

OPTIONS
    -f | --full      Output name and version (a la Module::Version 0.05)
    -I | --include   Include any number of directories to include as well
    -i | --input     Input file to read module names from 
    -l | --local-lib Additional local::lib dir to search
    -d | --dev       Show developer versions as 0.01_01 instead of 0.0101
    -q | --quiet     Do not error out if module doesn't exist

_END_HEREDOC
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Version::App - Application implementation for Module::Version

=head1 VERSION

version 0.201

=head1 SYNOPSIS

This is the CLI program's implementation as a module.

    use Module::Version::App;

    my $app = Module::Version::App->new;

    $app->run;

=head1 SUBROUTINES/METHODS

=head2 new

Create a new object.

=head2 run

Do all the grunt work.

=head2 parse_opts

Parsing the command line arguments using L<Getopt::Long>.

=head2 process

Parses extra arguments from L<Getopt::Long>.

=head2 help

Print a help menu for the application itself.

=head2 error($error)

Calls C<die> with a message.

=head2 warn($warning)

Calls C<warn> with a message.

=head1 EXPORT

Object Oriented, nothing is exported.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-module-version at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Version>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

This module sports 100% test coverage, but in case you have more issues...

You can find documentation for this module with the perldoc command.

    perldoc Module::Version

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Version>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Version>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Version>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Version/>

=back

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010-2018 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
