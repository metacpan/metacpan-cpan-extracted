package Net::ACME2::Challenge::http_01::Handler;

=encoding utf-8

=head1 NAME

Net::ACME2::Challenge::http_01::Handler - http-01 challenge handler

=head1 DESCRIPTION

This module handles the creation and removal of a domain control
validation (DCV) file for http-01 challenges. Creation happens on
instantiation; removal happens when the object is destroyed.

See L<Net::ACME2::Challenge::http_01> for a usage example.

=cut

use strict;
use warnings;
use autodie;

use Errno ();

our $ASSUME_UNIX_PATHS;

my @required = qw( key_authorization  challenge  document_root );

sub new {
    my ( $class, %opts ) = @_;

    #sanity
    my @missing = grep { !defined $opts{$_} } @required;
    die "Missing: [@missing]" if @missing;

    -d $opts{'document_root'} or die "Document root “$opts{'document_root'}” doesn’t exist!";

    my ($file_path, $dir);

    if ($ASSUME_UNIX_PATHS) {
        $file_path = $opts{'document_root'} . $opts{'challenge'}->path();
        $dir = substr( $file_path, rindex( $file_path, '/' ) );
    }
    else {
        require File::Spec;

        my @relpath = split m</>, $opts{'challenge'}->path();

        $file_path = File::Spec->catdir(
            $opts{'document_root'},
            @relpath,
        );

        $dir = File::Spec->catdir(
            $opts{'document_root'},
            @relpath[ 0 .. ($#relpath - 1) ],
        );
    }

    _mkdir_if_not_exists($dir);

    local ( $!, $^E );

    open my $wfh, '>', $file_path;
    chmod 0644, $file_path;
    syswrite $wfh, $opts{'key_authorization'};
    close $wfh;

    my $self = {
        _euid                  => $>,
        _path                  => $file_path,
        #_docroot_relative_path => $docroot_relative_path,
        #_content               => $opts{'key_authorization'},
    };

    return bless $self, $class;
}

#sub expected_content {
#    my ($self) = @_;
#
#    return $self->{'_content'};
#}
#
#sub verification_path {
#    my ($self) = @_;
#
#    return "/$self->{'_docroot_relative_path'}";
#}

sub DESTROY {
    my ($self) = @_;

    if ( $> != $self->{'_euid'} ) {
        die "XXX attempt to delete “$self->{'_path'}” with EUID $>; created with EUID $self->{'_euid'}!";
    }

    _unlink_if_exists( $self->{'_path'} );

    return;
}

sub _mkdir_if_not_exists {
    my ($dir) = @_;

    if (!-d $dir) {
        require File::Path;

        #cf. eval_bug.readme
        my $eval_err = $@;

        local ( $!, $^E );

        File::Path::make_path($dir);

        $@ = $eval_err;
    }

    return;
}

sub _unlink_if_exists {
    my ($path) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    local ( $!, $^E );

    eval { unlink $path; 1 } or do {
        die if $@->errno() != Errno::ENOENT();
    };

    $@ = $eval_err;

    return;
}

1;
