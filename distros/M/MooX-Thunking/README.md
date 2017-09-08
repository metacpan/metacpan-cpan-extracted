# NAME

MooX::Thunking - Allow Moo attributes to be "thunked"

# SYNOPSIS

    package Thunking;
    use Moo;
    use MooX::Thunking;
    use Types::TypeTiny -all;
    use Types::Standard -all;
    has children => (
      is => 'thunked',
      isa => CodeLike | ArrayRef[InstanceOf['Thunking']],
      required => 1,
    );

    package main;
    my $obj;
    $obj = Thunking->new(children => sub { [$obj] });

# DESCRIPTION

This is a [Moo](https://metacpan.org/pod/Moo) extension. It allows another value for the `is`
parameter to ["has" in Moo](https://metacpan.org/pod/Moo#has): "thunked". If used, this will allow you to 
transparently provide either a real value for the attribute, or a
["CodeLike" in Types::TypeTiny](https://metacpan.org/pod/Types::TypeTiny#CodeLike) that when called will return such a real
value.

# AUTHOR

Ed J

# LICENCE

The same terms as Perl itself.
