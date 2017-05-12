# $Id: KeyGenerator.pm 21415 2008-10-16 07:50:55Z daisuke $

package MooseX::WithCache::KeyGenerator;
use Moose::Role;

requires 'generate';

no Moose::Role;

1;

__END__

=head1 NAME

MooseX::WithCache::KeyGenerator - KeyGenerator Role

=head1 SYNOPSIS

    package MyKeyGenerator;
    use Moose;

    with 'MooseX::WithCache::KeyGenerator';

    no Moose;

    sub generate {
        my $key = ...;
        return $key;
    }

=cut