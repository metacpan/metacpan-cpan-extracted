#!/usr/bin/perl

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Digest qw( MD5 SHA1 );
    
    has md5_hash  => ( is => 'rw', isa => MD5  );
    has sha1_hash => ( is => 'rw', isa => SHA1 );
}

my $foo = Foo->new(
    md5_hash   => '3a59124cfcc7ce26274174c962094a20',
    sha1_hash  => '1dff4026f8d3449cc83980e0e6d6cec075303ae3'
);

print $foo->dump;