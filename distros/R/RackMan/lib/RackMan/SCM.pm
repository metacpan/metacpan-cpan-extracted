package RackMan::SCM;

use Cwd;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;


enum ScmType => [qw< none cvs svn bzr hg git >];

has type => (
    is => "ro",
    isa => "ScmType",
    required => 1,
);

has path => (
    is => "rw",
    isa => "Str",
);

has prefix => (
    is => "rw",
    isa => "Str",
);

has verbose => (
    is => "rw",
    isa => "Bool",
);


my %xlate = (
    bzr => {
        update => [ ["update"] ],
        commit => [ ["commit", "%0%", "-m", "%1%"], ["push"] ],
    },
    git => {
        update => [ ["pull"] ],
        commit => [ ["commit", "%0%", "-m", "%1%"], ["push"] ],
    },
    hg => {
        update => [ ["pull"], ["update"] ],
        commit => [ ["commit", "%0%", "-m", "%1%"], ["push"] ],
    },
);


#
# _exec()
# -----
sub _exec {
    my ($self, @batch) = @_;

    my $curdir = getcwd();
    chdir $self->path if $self->path;

    for my $cmd (@batch) {
        print $self->prefix, join " ", map { / / ? "'$_'" : $_ } @$cmd, "\n"
            if $self->verbose;

        system @$cmd;
    }

    chdir $curdir;
}


#
# add()
# ---
sub add {
    my ($self, @args) = @_;

    my $prog = $self->type;
    return if $prog eq "none";
    my @batch = ( [$prog, "add", $args[0]] );

    $self->_exec(@batch);
}


#
# commit()
# ------
sub commit {
    my ($self, @args) = @_;

    my $prog = $self->type;
    return if $prog eq "none";
    my @batch;

    if (ref $xlate{$prog}{commit}) {
        for my $cmd (@{ $xlate{$prog}{commit} }) {
            push @batch, [ $prog, map { s/%(\d)%/$args[$1]/; $_ } @$cmd ];
        }
    }
    else {
        push @batch, [ $prog, "commit", $args[0], "-m", $args[1] ];
    }

    $self->_exec(@batch);
}


#
# update()
# ------
sub update {
    my ($self, @args) = @_;

    my $prog = $self->type;
    return if $prog eq "none";
    my @batch;

    if (ref $xlate{$prog}{update}) {
        for my $cmd (@{ $xlate{$prog}{update} }) {
            push @batch, [ $prog, map { s/%(\d)%/$args[$1]/; $_ } @$cmd ];
        }
    }
    else {
        $args[0] ||= ".";
        push @batch, [ $prog, "update", $args[0] ];
    }

    $self->_exec(@batch);
}


__PACKAGE__->meta->make_immutable

__END__

=pod

=head1 NAME

RackMan::SCM - Perform basic operations with any SCM

=head1 SYNOPSIS

    use RackMan::SCM;

    chdir "src";

    my $scm = RackMan::SCM->new({ type => "git", path => "src" });
    $scm->update;

    my $file = "lipsum.txt";
    open my $fh, ">", $file or die $!;
    print {$fh} "Lorem ipsum sit amet";
    close $fh;

    $scm->add($file);
    $scm->commit($file, "added $file for great justice");


=head1 DESCRIPTION

This module allows to perform basic operations in a generic way,
whatever the backend SCM is. It can be seen as a kind of very
lightweight VCI. It currently knows the following SCM: CVS,
Subversion, Bazaar, Mercurial, Git.

When possible, use the C<get_scm()> method of a C<RackMan> instance
to obtain the SCM expected by the user.


=head1 METHODS

=head2 new

create and return a new object


=head2 update

update the given path


=head2 add

add the given path


=head2 commit

commit the given path with the given message


=head1 ATTRIBUTES

=head2 type

String, indicates the type of SCM to use: C<cvs>, C<svn>,
C<bzr>, C<hg>, C<git>


=head2 path

String, current working directory


=head2 prefix

String, prefix printed before the command when in verbose mode


=head2 verbose

Boolean, whether the command are to be printed before being executed


=head1 AUTHOR

Sebastien Aperghis-Tramoni (sebastien@aperghis.net)

=cut

