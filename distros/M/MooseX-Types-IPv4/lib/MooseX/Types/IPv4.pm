package MooseX::Types::IPv4; {

  use 5.008008;

  use MooseX::Types
    -declare => [qw/cidr ip2 ip3 ip4 ip4_binary netmask netmask4_binary/];


  use Moose::Util::TypeConstraints;
  use MooseX::Types::Moose qw/Int Num Str/;

  our $VERSION = '0.03';


  my $ip2valr .= '';
  my $ip3valr .= '';

  my $ip4valr .= '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}';
     $ip4valr .= '(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';


  my $nmvalr .= '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}';
     $nmvalr .= '(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$';


  subtype cidr,
    as Int,
    where { /^(?:[0-2]?[0-9]||3[0-2])/ },
    message { "$_ is not a valid CIDR " };


  ## No validation here yet. This is for a.b notation.
  ## I don't use it, but prototyped it in anyway.
  subtype ip2,
    as Str,
    where { /$ip2valr/ },
    message { "$_ is not a valid ip address " };


  ## No validation here yet. This is for a.b.c notation.
  ## I don't use it, but prototyped it in anyway.
  subtype ip3,
    as Str,
    where { /$ip3valr/ },
    message { "$_ is not a valid ip address " };


  ## This will validate a regular dot-quad ip address. I personally only use
  ## this to validate user input before converting my ip addresses to binary
  ## which is how I do all of my ip address manipulations.
  subtype ip4,
    as Str,
    where { /$ip4valr/ },
    message { "$_ is not a valid ip address " };


  subtype ip4_binary,
    as Num, #[ Base => '2', Precision => '32' ],
    where { /^[01]{32}$/ },
    message { "$_ is not a valid binary IP address " };


  coerce ip4_binary,
    from 'MooseX::Types::IPv4::ip4',
    via { unpack('B32', pack('C4', split(/\D/, $_))); };


  coerce ip4_binary,
    from 'MooseX::Types::IPv4::ip3',
    via { unpack('B32', pack('C2S', split(/\D/, $_))); };


  coerce ip4_binary,
    from 'MooseX::Types::IPv4::ip2',
    via { unpack('B32', pack('CL', split(/\D/, $_))); };


  subtype netmask,
    as Str,
    where { /$nmvalr/ },
    message { "$_ is not a valid netmask: " };


  subtype netmask4_binary,
    as Num, #[ Base => '2', Precision => '32' ],
    where { length($_) == 32 and /^(?:[1]{0,32}[0]{0,32})$/ },
    message { "$_ is not a valid binary netmask address " };


  coerce netmask4_binary,
    from 'MooseX::Types::IPv4::netmask',
    via { unpack('B32', pack('C4', split(/\D/, $_))); };


  coerce netmask4_binary,
    from 'MooseX::Types::IPv4::cidr',
    via { ( ("1" x $_) . ("0" x (32 - $_)) ); };

}

1;

__END__

=head1 NAME

MooseX::Types::IPv4 - IP Address types

=head1 SYNOPSIS

    package MyClass;
    use Moose;
    use MooseX::Types::IPv4 qw/ip2 ip3 ip4/;
    use namespace::autoclean;

    has 'ipaddress2' => ( isa => ip2, is => 'rw' required => 1 );
    has 'ipaddress3' => ( isa => ip3, is => 'rw' required => 1 );
    has 'ipaddress4' => ( isa => ip4, is => 'rw' required => 1 );

=head1 DESCRIPTION

Moose type constraints that provide ip validation

=head1 SEE ALSO

=over

=item L<Moose::Util::TypeConstraints>

=item L<MooseX::Types>

=back

=head1 AUTHORS

Kyle Hultman C<< <khultman@gmail.com> >>

=head1 COPYRIGHT

Copyright 2009 the above L<AUTHORS>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
