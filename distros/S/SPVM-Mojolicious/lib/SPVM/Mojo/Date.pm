package SPVM::Mojo::Date;



1;

=head1 Name

SPVM::Mojo::Date - HTTP date

=head1 Description

Mojo::Date class in L<SPVM> implements HTTP date and time functions, based on L<RFC 7230|https://tools.ietf.org/html/rfc7230>, L<RFC
7231|https://tools.ietf.org/html/rfc7231> and L<RFC 3339|https://tools.ietf.org/html/rfc3339>.

=head1 Usage

  use Mojo::Date;
  use Sys;

  # Parse
  my $date = Mojo::Date->new("Sun, 06 Nov 1994 08:49:37 GMT");
  say $date->epoch;

  # Build
  my $date = Mojo::Date->new(Sys->time + 60);
  say $date->to_string;

=head1 Fields

=head2 epoch

C<has epoch : virtual rw double;>

Epoch seconds with a fractional part, defaults to the current time.

This is a virtual field. The real value is set to and got from L</"epoch_sec"> and L</"epoch_nsec"> fields.

=head2 epoch_sec

C<has epoch_sec : rw long;>

Epoch seconds.

=head2 epoch_nsec

C<has epoch_nsec : rw long;>

Epoch nano seconds.

=head1 Class Methods

=head2 new

C<static method new : Mojo::Date ($date_value : object of string|L<Long|SPVM::Long> = undef);>

Construct a new L<Mojo::Date> object and L</"parse"> date if necessary.

Examples:

  my $date = Mojo::Date->new;
  my $date = Mojo::Date->new("Sun Nov  6 08:49:37 1994");
  my $date = Mojo::Date->new(Sys->time + 60);
  my $date = Mojo::Date->new("784111777.21");

=head1 Instance Methods

=head2 parse

C<method parse : void ($date : string);>

Parse date.

  # Epoch
  say Mojo::Date->new("784111777")->epoch;
  
  say Mojo::Date->new("784111777.21")->epoch;
  
  # RFC 822/1123
  say Mojo::Date->new("Sun, 06 Nov 1994 08:49:37 GMT")->epoch;
  
  # RFC 850/1036
  say Mojo::Date->new("Sunday, 06-Nov-94 08:49:37 GMT")->epoch;
  
  # Ansi C asctime()
  say Mojo::Date->new("Sun Nov  6 08:49:37 1994")->epoch;
  
  # RFC 3339
  say Mojo::Date->new("1994-11-06T08:49:37Z")->epoch;
  say Mojo::Date->new("1994-11-06T08:49:37")->epoch;
  say Mojo::Date->new("1994-11-06T08:49:37.21Z")->epoch;
  say Mojo::Date->new("1994-11-06T08:49:37+01:00")->epoch;
  say Mojo::Date->new("1994-11-06T08:49:37-01:00")->epoch;

=head2 to_datetime

C<method to_datetime : string ();>

Render L<RFC 3339|https://tools.ietf.org/html/rfc3339> date and time.

  # "1994-11-06T08:49:37Z"
  Mojo::Date->new(784111777L)->to_datetime;

  # "1994-11-06T08:49:37.21Z"
  Mojo::Date->new("784111777.21")->to_datetime;

=head2 to_string

C<method to_string : string ();>

Render date suitable for HTTP messages.

  # "Sun, 06 Nov 1994 08:49:37 GMT"
  Mojo::Date->new(784111777L)->to_string;

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

