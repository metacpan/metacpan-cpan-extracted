package SPVM::Mojo::Parameters;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::Parameters - Parameters

=head1 Description

Mojo::Parameters class in L<SPVM> is a container for form parameters used by L<Mojo::URL|SPVM::Mojo::URL>, based on L<RFC
3986|https://tools.ietf.org/html/rfc3986> and the L<HTML Living Standard|https://html.spec.whatwg.org>.

=head1 Usage

  use Mojo::Parameters;
  
  # Parse
  my $params = Mojo::Parameters->new("foo=bar&baz=23");
  $params->param("baz");
  say $params->to_string;
  
  # Build
  my $params = Mojo::Parameters->new({foo => "bar", baz => 23});
  $params->pairs_list->push_([i => "♥ mojolicious"]);
  say $params->to_string;

=head1 Fields

=head2 pairs

C<has pairs : virtual rw string[];>

Parsed parameter pairs.

This is a virtual field. The value is got from and stored to L</"pairs_list">.

Examples:

  # Remove all parameters
  $params->set_pairs(new string[0]);

=head2 pairs_list

C<has pairs_list : rw L<StringList|SPVM::StringList>;>

Parsed parameter pairs. Note that this method will normalize the parameters.

=head1 Class Methods

C<static method new : L<Mojo::Parameters|SPVM::Mojo::Parameters> ($params_value : object of string|object[] = undef);>

Construct a new L<Mojo::Parameters|SPVM::Mojo::Parameters> object and L</"parse"> parameters if necessary.

Examples:

  my $params = Mojo::Parameters->new;
  my $params = Mojo::Parameters->new("foo=b%3Bar&baz=23");
  my $params = Mojo::Parameters->new({foo => "b&ar"});
  my $params = Mojo::Parameters->new({foo => ["ba&r", "baz"]});
  my $params = Mojo::Parameters->new({foo => ["bar", "baz"], bar => 23});

=head1 Instance Methods

=head2 append

C<method append : void ($pairs : object of object[]|L<Mojo::Parameters|SPVM::Mojo::Parameters>);>

Append parameters. Note that this method will normalize the parameters.

Examples:

  # "foo=bar&foo=baz"
  Mojo::Parameters->new("foo=bar")->append(Mojo::Parameters->new("foo=baz"));
  
  # "foo=bar&foo=baz"
  Mojo::Parameters->new("foo=bar")->append({foo => "baz"});
  
  # "foo=bar&foo=baz&foo=yada"
  Mojo::Parameters->new("foo=bar")->append({foo => ["baz", "yada"]});
  
  # "foo=bar&foo=baz&foo=yada&bar=23"
  Mojo::Parameters->new("foo=bar")->append({foo => ["baz", "yada"], bar => 23});

=head2 clone

C<method clone : L<Mojo::Parameters|SPVM::Mojo::Parameters> ();>

Return a new L<Mojo::Parameters|SPVM::Mojo::Parameters> object cloned from these parameters.

=head2 every_param

C<method every_param : string[] ($name : string);>

Similar to L</"param">, but returns all values sharing the same name as an array reference. Note that this method will
normalize the parameters.

Examples:

  # Get first value
  say $params->every_param("foo")->[0];

=head2 merge

C<method merge : void ($parameters : object of object[]|L<Mojo::Parameters|SPVM::Mojo::Parameters>);>

Merge parameters. Note that this method will normalize the parameters.

  # "foo=baz"
  Mojo::Parameters->new("foo=bar")->merge(Mojo::Parameters->new("foo=baz"));

  # "yada=yada&foo=baz"
  Mojo::Parameters->new("foo=bar&yada=yada")->merge({foo => "baz"});

  # "yada=yada"
  Mojo::Parameters->new("foo=bar&yada=yada")->merge({foo => undef});

=head2 names

C<method names : string[] ();>

Return an array reference with all parameter names.

Examples:

  # Names of all parameters
  for my $name (@{$params->names}) {
    say $name;
  }

=head2 param

C<method param : string ($name : string);>

Get parameter values. If there are multiple values sharing the same name, and you want to access more than just the
last one, you can use L</"every_param">. Note that this method will normalize the parameters.

Examples:

  my $value = $params->param("foo");

=head2 set_param

C<method set_param : void ($name : string, $value : object of string|string[]);>

Set parameter values. If there are multiple values sharing the same name, and you want to access more than just the
last one, you can use L</"every_param">. Note that this method will normalize the parameters.

Examples:

  $params->set_param(foo => "ba&r");
  $params->set_param(foo => ["ba&r", "baz"]);
  $params->set_param(foo => ["ba;r", "baz"]);

=head2 parse

C<method parse : void ($params_value : object of string|object[]);>

Parse parameters.

=head2 remove

C<method remove : void ($name : string);>

Remove parameters. Note that this method will normalize the parameters.

Examples:

  # "bar=yada"
  Mojo::Parameters->new("foo=bar&foo=baz&bar=yada")->remove("foo");

=head2 to_hash

C<method to_hash : L<Hash|SPVM::Hash> ();>

Turn parameters into a hash reference. Note that this method will normalize the parameters.

  # "baz"
  Mojo::Parameters->new("foo=bar&foo=baz")->to_hash->get("foo")->(string[])->[1];

=head2 to_string

C<method to_string : string ();>

Turn parameters into a string.

  # "foo=bar&baz=23"
  Mojo::Parameters->new->set_pairs([foo => "bar", baz => "23"])->to_string;

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

