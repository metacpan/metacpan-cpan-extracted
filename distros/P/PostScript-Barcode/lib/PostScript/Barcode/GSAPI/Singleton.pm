package PostScript::Barcode::GSAPI::Singleton;
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use GSAPI qw();
use MooseX::Singleton qw(has);

our $VERSION = '0.006';

# new_instance returns an object of type GSAPI::instance.
# MooseX::Singleton also has a method named "instance".
# So I name the GSAPI instance "handle" to avoid confusion.
has 'handle' => (
    is      => 'ro',
    isa     => 'GSAPI::instance',
    default => sub {return GSAPI::new_instance;},
);

sub DEMOLISH {
    my ($self) = @_;
    GSAPI::delete_instance($self->handle);
    return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PostScript::Barcode::GSAPI::Singleton - singleton class wrapper for GSAPI


=head1 VERSION

This document describes C<PostScript::Barcode::GSAPI::Singleton> version C<0.006>.


=head1 SYNOPSIS

    use PostScript::Barcode::GSAPI::Singleton qw();


=head1 DESCRIPTION

See L<MooseX::Singleton>.


=head1 INTERFACE

=head2 Attributes

=head3 C<handle>

Type C<GSAPI::instance>
