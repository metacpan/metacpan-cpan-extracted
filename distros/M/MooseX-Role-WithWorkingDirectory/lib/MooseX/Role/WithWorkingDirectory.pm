package MooseX::Role::WithWorkingDirectory;
BEGIN {
  $MooseX::Role::WithWorkingDirectory::VERSION = '0.02';
}

use Moose::Role;

sub with_wd {
    my ( $self, $directory ) = @_;

    return bless [ $self, $directory ],
        'MooseX::Role::WithWorkingDirectory::Proxy';
}

package
    MooseX::Role::WithWorkingDirectory::Proxy;

use strict;

use Cwd ();
use autodie qw(chdir);
use vars qw($AUTOLOAD);

sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return unless $method =~ /[a-z]/;
    my $directory;

    ( $self, $directory ) = @$self;

    my $cwd = Cwd::getcwd();
    chdir $directory;

    if(wantarray) {
        my @result = eval { $self->$method(@args) };
        chdir $cwd;

        die if $@;
        return @result;
    } else {
        my $result = eval { $self->$method(@args) };
        chdir $cwd;

        die if $@;
        return $result;
    }
}

1;



=pod

=head1 NAME

MooseX::Role::WithWorkingDirectory - Syntactic sugar for running a method while in a directory

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  package MyObject;
  use Moose;
  with 'MooseX::Role::WithWorkingDirectory';

  sub list_files {
    system 'ls';
  }

  # later...
  
  my $object = MyObject->new;

  $object->with_wd('/tmp/something')->list_files; # lists files in /tmp/something
  $object->list_files; # lists files in original CWD

=head1 DESCRIPTION

Use this L<Moose> role to add the C<with_wd> method to your classes.

=head1 METHODS

=head2 $object->with_wd($directory)

Changes the current working directory to C<$directory>, and runs methods in
that directory.  When those methods return, your application will be back
in its original working directory.

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Role-WithWorkingDirec
tory

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut


__END__

# ABSTRACT: Syntactic sugar for running a method while in a directory

