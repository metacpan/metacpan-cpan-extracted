package MooX::TO_JSON;

use warnings;
use strict;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Class::Method::Modifiers qw(install_modifier);

sub import {
  my ($class) = @_;
  my $target = caller;

  my @to_json;
  install_modifier $target, 'fresh', 'TO_JSON', sub {
    my $self = shift;
    my @structure = ();
    foreach my $rule (@to_json) {

      if($rule->{omit_if_empty}) {
        next unless $self->${\$rule->{predicate}};
      }

      my $value = $self->${\$rule->{field}};
      if(my $type = $rule->{type}) {
        $value = ''+$value if $type == 1;
        $value = 0+$value if $type == 2;
        $value = $value ? \1:\0 if $type == 3;
      }
      
      push @structure, (
        $rule->{mapped_field} => $value,
      );
    }
    @structure = $self->modify_json(@structure) if $self->can('modify_json');
    return +{ @structure };
  };

  my %types = (
    str => 1,
    num => 2,
    bool => 3);

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attr, %opts) = @_;

    my $json = delete $opts{json};
    return $orig->($attr, %opts) unless $json;

    my $field = $attr;
    $field =~ s/^\+//;

    unless(ref $json) {
      my $json_to_split = $json eq '1' ? ',':$json;
      my ($mapped_field, $extra1, $extra2) = split(',', $json_to_split);
      my ($type, $omit_if_empty);

      if(my $found_type = $types{$extra1||''}) {
        $type = $found_type;
      }

      my $predicate = $opts{predicate} ||= "has_".$field;
      
      $omit_if_empty = 1 if (($extra1||'') eq 'omit_if_empty') || (($extra2||'') eq 'omit_if_empty');

      $json = +{
        field => $field,
        mapped_field => ($mapped_field ? $mapped_field : $field),
        type => $type,
        omit_if_empty => $omit_if_empty,
        predicate => $predicate,
      };
    }

    push @to_json, $json;
    
    return $orig->($attr, %opts);
  };
}

1;

=head1 NAME

MooX::TO_JSON - Generate a TO_JSON method from attributes.

=head1 SYNOPSIS

    package Local::User;

    use Moo;
    use MooX::TO_JSON;

    has name => (is=>'ro', json=>1);
    has age => (is=>'ro', json=>'age-years,num');
    has alive => (is=>'ro', json=>',bool');
    has possibly_empty => (is=>'ro', json=>',omit_if_empty');
    has not_encoded => (is=>'ro');

    # Optional method to shove in some extra keys
    sub modify_json {
      my ($self, %data) = @_;
      return (%data, extra_stuff => 1);
    }

    use JSON::MaybeXS;

    my $json = JSON::MaybeXS->new(convert_blessed=>1);
    my $user = Local::User->new(
      name=>'John',
      age=>25,
      alive=>'yes',
      not_encoded=>'internal');

    my $encoded = $json->encode($user);

The value of C<$encoded> is:

    {
       "alive" : true,
       "name" : "John",
       "age-years" : 25,
       "extra_stuff": 1
    }
   
Please note that the JSON spec does not preserve hash order, so the keys above
could be arranged differently.

=head1 DESCRIPTION

Make it easier to correctly encode your L<Moo> object into JSON.  It does this
by inspecting your attributes and injection a C<TO_JSON> method into your class.
You can tag how the attribute will serialize to JSON (forcing it into string or
number / boolean).  

    has name => (is=>'ro', json=>1);

Setting the C<json> argument to 1 will serialize the attribute value to JSON use
the defaults (that is the field name is the same as the attribute name, value is
serialized even if C<undef> and no value coercions (to number or boolean for example)
are forced).

    has age => (is=>'ro', json=>'age-years,num');

Here C<age> will be mapped to 'age-years' and the value forced into number context so
that when the JSON encoder touches it the serialized value will be a number not a string.

    has alive => (is=>'ro', json=>',bool');

In this case the value is forced to boolean JSON context.

    has possibly_empty => (is=>'ro', json=>',omit_if_empty');

Lastly if the final tag in the 'json' string is 'omit_if_empty' we will omit including
the field in the JSON output IF the attribute is not present (please note C<undef> is
considered 'present/existing'.)  In order to do this we need to set a C<predicate> arg
for the attribute (or use one if you define it).  This will slighly pollute the object
namespace with the predicate method for each attribute you mark such.

Your class can also contain a method C<modify_json> which
takes the serialized attributes and allows you to add to them or modify them.

=head1 AUTHOR

John Napiorkowski (cpan:JJNAPIORK) <jjnapiork@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2019 by </AUTHOR> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
