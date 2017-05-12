package MooX::Types::SetObject;
use strict;
use warnings FATAL => 'all';
use MooX::Types::MooseLike qw(exception_message);
use Scalar::Util;
use Exporter 5.57 'import';
our @EXPORT_OK = ();

our $VERSION = '1.01';

my $type_definitions = [
  {
    name => 'SetObject',
    test => sub {
      require Scalar::Util;
      defined $_[0] and
        Scalar::Util::blessed($_[0]) and $_[0]->isa("Set::Object");
      },
    message         => sub { return exception_message($_[0], 'a Set::Object') },
    parameterizable => sub { $_[0]->members },
    inflate         => 0,
  },
  ];

MooX::Types::MooseLike::register_types($type_definitions, __PACKAGE__);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

1;

__END__

=head1 NAME

MooX::Types::SetObject - Set::Object type

=head1 SYNOPSIS

    package MyPackage;
    use Moo;
    use MooX::Types::MooseLike::Base qw(Int);
    use MooX::Types::SetObject qw(SetObject);

    # a Set::Object of integers
    has "int_objects" => (
        isa => SetObject[Int],
    );
