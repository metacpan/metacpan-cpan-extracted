package Net::ACME::Challenge::Pending::http_01::Handler;

=encoding utf-8

=head1 NAME

Net::ACME::Challenge::Pending::http_01::Handler - http-01 challenge handler

=head1 DESCRIPTION

This module handles the creation and removal of a domain control file for
http-01 challenges. Creation happens on instantiation; removal happens
when the object is destroyed.

See C<Net::ACME::Challenge::Pending::http_01>’s documentation for more
information, including a usage example.

To handle challenges that have been unhandled (successfully or not),
see C<Net::ACME::Challenge>.

=cut

use strict;
use warnings;

use autodie;

use Errno      ();
use File::Spec ();

use Net::ACME::Constants ();

#docroot, token, key_authz
sub new {
    my ( $class, %opts ) = @_;

    my $docroot_relative_path = "$Net::ACME::Constants::HTTP_01_CHALLENGE_DCV_DIR_IN_DOCROOT/$opts{'token'}";

    my $file_path = "$opts{'docroot'}/$docroot_relative_path";

    _mkdir_if_not_exists("$opts{'docroot'}/$Net::ACME::Constants::HTTP_01_CHALLENGE_DCV_DIR_IN_DOCROOT");

    local ( $!, $^E );

    open my $wfh, '>', $file_path;
    chmod 0644, $file_path;
    syswrite $wfh, $opts{'key_authz'};
    close $wfh;

    my $self = {
        _euid                  => $>,
        _path                  => $file_path,
        _docroot_relative_path => $docroot_relative_path,
        _content               => $opts{'key_authz'},
    };

    return bless $self, $class;
}

sub expected_content {
    my ($self) = @_;

    return $self->{'_content'};
}

sub verification_path {
    my ($self) = @_;

    return "/$self->{'_docroot_relative_path'}";
}

sub DESTROY {
    my ($self) = @_;

    if ( $> != $self->{'_euid'} ) {
        die "XXX attempt to delete “$self->{'_path'}” with EUID $>; created with EUID $self->{'_euid'}!";
    }

    _unlink_if_exists( $self->{'_path'} );

    return;
}

sub _mkdir_if_not_exists {
    my ($path) = @_;

    #cf. eval_bug.readme
    my $eval_err = $@;

    local ( $!, $^E );

    my @ppath = File::Spec->splitdir($path);
    pop @ppath;
    my $ppath_str = File::Spec->catdir(@ppath);

    for my $p ($ppath_str, $path) {
        eval { mkdir $p };
        die if $@ && $@->errno() != Errno::EEXIST();
    }

    $@ = $eval_err;

    return;
}

sub _unlink_if_exists {
    my ($path) = @_;

    local $@;
    local ( $!, $^E );
    eval { unlink $path };
    die if $@ && $@->errno() != Errno::ENOENT();

    return;
}

1;
