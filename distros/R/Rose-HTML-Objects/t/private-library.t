#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Test::More tests => 179;
#use Test::More 'no_plan';

use_ok('Rose::HTML::Objects');

use File::Spec;
use File::Path;

#
# In-memory
#

my %code =
(
  'My::HTML::Object::Message::Localizer' =>
  {
    filter => sub { s/__FOO__//g },
    code   =><<'EOF',
sub get_localized_message_text__FOO____BAR__
{
  my($self) = shift;
  no warnings 'uninitialized';
  return uc $self->SUPER::get_localized_message_text(@_);
}
EOF
  },

  'My::HTML::Form::Field::File' =><<'EOF',
our $JCS = 123;
EOF
);

#$Rose::HTML::Objects::Debug = 3;
my($packages, $perl) = 
  Rose::HTML::Objects->make_private_library(in_memory    => 1, 
                                            prefix       => 'My::',
                                            class_filter => sub { !/Email/ },
                                            code_filter  => sub {  s/__BAR__//g },
                                            code         => \%code);

is(scalar @My::HTML::Form::Field::Email::ISA, 0, 'class_filter');

QUIET:
{
  no warnings;
  is($My::HTML::Form::Field::File::JCS, 123, 'code additions');
}

my $field     = My::HTML::Form::Field::Text->new(name => 'x', required => 1);
my $std_field = Rose::HTML::Form::Field::Text->new(name => 'x', required => 1);

$field->validate;
$std_field->validate;

is($field->error, uc $std_field->error, 'upcase error 1');

$field = My::HTML::Form::Field::PopUpMenu->new(name => 'x');

$field->options(a => 'Apple', b => 'Pear');

is(ref $field->option('a'), 'My::HTML::Form::Field::Option', 'option 1');

my $object = My::HTML::Object->new('xyz');

is($object->validate_html_attrs, 0, 'generic object 1');

eval { $object->html_attr(foo => 'bar') };
ok(!$@, 'generic object 2');

foreach my $type (My::HTML::Object->object_type_names)
{
  my $std_class = Rose::HTML::Object->object_type_class($type);
  (my $new_class = $std_class) =~ s/^Rose::/My::/;

  is(My::HTML::Object->object_type_class($type), $new_class, "object type class: $type");
}

GENERIC_FIELD:
{
  package My::Field;
  our @ISA = ('My::HTML::Form::Field');

  package main;
  $field = My::Field->new;
  ok($field->isa('Rose::HTML::Form::Field'), 'generic field 1');
}

#
# Module files
#

my $lib_dir = File::Spec->catfile($Bin, 'tmplib');

mkdir($lib_dir)  unless(-d $lib_dir);
die "Could not mkdir($lib_dir) - $!"  unless(-d $lib_dir);

%code =
(
  'My2::HTML::Object::Message::Localizer' =><<'EOF',
our $TwiddleCase = 1;

sub get_localized_message_text
{
  my($self) = shift;

  if($TwiddleCase)
  {
    no warnings 'uninitialized';
    return rand > 0.5 ? uc $self->SUPER::get_localized_message_text(@_) :
                        lc $self->SUPER::get_localized_message_text(@_);
  }
  else
  {
    return $self->SUPER::get_localized_message_text(@_);
  }
}
EOF

  'My2::HTML::Object::Messages' =><<'EOF',
use constant FIELD_ERROR_BAD_NICKNAME    => 100_000;
use constant FIELD_ERROR_BAD_NICKNAME_AR => 100_001;
use constant FIELD_ERROR_TOO_MANY_DAYS   => 100_002;

use constant FIELD_LABEL_NICKNAME        => 200_000;
EOF

  'My2::HTML::Object::Errors' =><<'EOF',
use constant FIELD_ERROR_BAD_NICKNAME    => 100_000;
use constant FIELD_ERROR_BAD_NICKNAME_AR => 100_001;
use constant FIELD_ERROR_TOO_MANY_DAYS   => 100_002;
EOF
);

$packages =
  Rose::HTML::Objects->make_private_library(modules_dir => $lib_dir, 
                                            overwrite   => 1,
                                            prefix      => 'My2::',
                                            code        => \%code);

unshift(@INC, $lib_dir);

GENERIC_FIELD:
{
  package My2::Field;
  require My2::HTML::Form::Field;
  our @ISA = ('My2::HTML::Form::Field');

  package main;
  $field = My2::Field->new;
  ok($field->isa('Rose::HTML::Form::Field'), 'generic field 2');
}

require My2::HTML::Form::Field::Text;

$field     = My2::HTML::Form::Field::Text->new(name => 'x', required => 1);
$std_field = Rose::HTML::Form::Field::Text->new(name => 'x', required => 1);

$field->validate;
$std_field->validate;

my @errors;

for(1 .. 10)
{
  push(@errors, $field->error . '');
}

ok((scalar grep { lc $std_field->error } @errors), 'lowercase error 1');
ok((scalar grep { lc $std_field->error } @errors), 'uppercase error 1');

require My2::HTML::Form::Field::PopUpMenu;

$field = My2::HTML::Form::Field::PopUpMenu->new(name => 'x');

$field->options(a => 'Apple', b => 'Pear');

is(ref $field->option('a'), 'My2::HTML::Form::Field::Option', 'option 1');

require My2::HTML::Object;

$object = My2::HTML::Object->new('xyz');

is($object->validate_html_attrs, 0, 'generic object 1');

eval { $object->html_attr(foo => 'bar') };
ok(!$@, 'generic object 2');

foreach my $type (My2::HTML::Object->object_type_names)
{
  my $std_class = Rose::HTML::Object->object_type_class($type);
  (my $new_class = $std_class) =~ s/^Rose::/My2::/;

  is(My2::HTML::Object->object_type_class($type), $new_class, "object type class: $type");
}

my @parts = split('::', 'My2::HTML::Form::Field::Nickname');
$parts[-1] .= '.pm';

my $nick_pm = File::Spec->catfile($lib_dir, @parts);
#warn "# WRITE: $nick_pm\n";

open(my $fh, '>', $nick_pm) or die "Could not create '$nick_pm' - $!";

my $code=<<'EOF';
package My2::HTML::Form::Field::Nickname;

use My2::HTML::Object::Errors qw(FIELD_ERROR_BAD_NICKNAME);
use My2::HTML::Object::Messages qw(FIELD_LABEL_NICKNAME);

use base qw(My2::HTML::Form::Field::Text);

sub init
{
  my($self) = shift;
  $self->label_id(FIELD_LABEL_NICKNAME);
  $self->SUPER::init(@_);
}

sub validate
{
  my($self) = shift;

  my $ret = $self->SUPER::validate(@_);
  return $ret  unless($ret);

  my $nick  = $self->internal_value;
  my $class = $self->html_attr('class') || 'default';

  if($nick =~ /bob/)
  {
    $self->error_id(FIELD_ERROR_BAD_NICKNAME, { nickname => $nick, class => $class, list => [ 'a' .. 'e' ] });
    return 0;
  }
  elsif($nick =~ /lob/)
  {
    $self->error_id(FIELD_ERROR_BAD_NICKNAME_AR, [ $class, [ 'a' .. 'e' ], $nick ]);
    return 0;
  }

  return 1;
}

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

1;

__DATA__

[% LOCALE en %]

FIELD_ERROR_BAD_NICKNAME = "[class] - \\\[\]Invalid nickname: [@list]:[nickname]"
FIELD_ERROR_BAD_NICKNAME_AR = "[1] - \\\[\]Invalid nickname: [@2]:[3]"

FIELD_LABEL_NICKNAME = "Nickname"

[% LOCALE fr %]

FIELD_ERROR_BAD_NICKNAME = "[class] - \\\[\]Le nickname est mal: [@list]:[nickname]"

FIELD_LABEL_NICKNAME = "Le Nickname"

EOF

print $fh $code;
close($fh) or die "Could not write '$nick_pm' - $!";

require My2::HTML::Form::Field::Nickname;

$field = My2::HTML::Form::Field::Nickname->new;

is(ref($field->localizer), 'My2::HTML::Object::Message::Localizer', 'custom field localizer');

my $label = $field->label . '';

ok($label eq 'nickname' || $label eq 'NICKNAME', 'custom field label (en)');

$field->locale('fr');

$label = $field->label . '';

ok($label eq 'le nickname' || $label eq 'LE NICKNAME', 'custom field label (fr)');

BLAH:
{
  no warnings;
  $My2::HTML::Object::Message::Localizer::TwiddleCase = 0;
}

$field->input_value('lob');
$field->validate;
is($field->error . '', 'default - \[]Invalid nickname: a, b, c, d, e:lob', 'placeholders (arrayref, fallback) 1');

$field->html_attr(class => 'c');
$field->validate;
is($field->error. '', 'c - \[]Invalid nickname: a, b, c, d, e:lob', 'placeholders (arrayref, fallback) 2');

$field->input_value('bob');
$field->validate;

$field->locale('en');
is($field->error. '', 'c - \[]Invalid nickname: a, b, c, d, e:bob', 'placeholders (hashref) 1');

$field->locale('fr');
is($field->error. '', 'c - \[]Le nickname est mal: a, b, c, d, e:bob', 'placeholders (hashref) 2');

require My2::HTML::Form;

My2::HTML::Form->field_type_class
(
  nick => 'My2::HTML::Form::Field::Nickname',
);

# My2::HTML::Form->field_type_class
# (
#   nickname => 'My2::HTML::Form::Field::Nickname',
# );

My2::HTML::Form->add_field_type_classes
(
  #nick     => 'My2::HTML::Form::Field::Nickname',
  nickname => 'My2::HTML::Form::Field::Nickname',
);

my $form = My2::HTML::Form->new;
$field = My2::HTML::Form::Field::Nickname->new;
$field->html_attr(class => 'c');

$form->add_field(nick => $field);

$form->params(nick => 'bob');
$form->init_fields;
$form->validate;

is($form->field('nick')->error. '', 'c - \[]Invalid nickname: a, b, c, d, e:bob', 'form locale 1');

$form->locale('fr');

is($form->field('nick')->error. '', 'c - \[]Le nickname est mal: a, b, c, d, e:bob', 'form locale 2');

$form = My2::HTML::Form->new;

$form->add_field(nick => { type => 'nick', class => 'c' });

$form->params({nick => 'bob'});
$form->init_fields;
$form->validate;

is($form->field('nick')->error. '', 'c - \[]Invalid nickname: a, b, c, d, e:bob', 'localizer locale 1');

My2::HTML::Object->localizer->locale('fr');

is($form->field('nick')->error. '', 'c - \[]Le nickname est mal: a, b, c, d, e:bob', 'localizer locale 2');

My2::HTML::Object->localizer->locale('en');

#
# Days field
#

@parts = split('::', 'My2::HTML::Form::Field::Days');
$parts[-1] .= '.pm';

my $days_pm = File::Spec->catfile($lib_dir, @parts);
#warn "# WRITE: $days_pm\n";

open($fh, '>', $days_pm) or die "Could not create '$days_pm' - $!";

$code=<<'EOF';
package My2::HTML::Form::Field::Days;

use My2::HTML::Object::Errors qw(FIELD_ERROR_TOO_MANY_DAYS);

use base qw(My2::HTML::Form::Field::Integer);


if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

1;

__DATA__

[% LOCALE en %]

FIELD_ERROR_TOO_MANY_DAYS = "Too many days."
FIELD_ERROR_TOO_MANY_DAYS(one) = "One day is too many."
FIELD_ERROR_TOO_MANY_DAYS(two) = "Two days is too many."
FIELD_ERROR_TOO_MANY_DAYS(few) = "[count] days is too many (few)."

[% LOCALE fr %]

FIELD_ERROR_TOO_MANY_DAYS = "Trop de jours."

EOF

print $fh $code;
close($fh) or die "Could not write '$days_pm' - $!";

require My2::HTML::Form::Field::Days;

require My2::HTML::Object::Errors;

My2::HTML::Form::Field::Days->localizer->load_messages_from_string(<<"EOF");
[% LOCALE en %]

FIELD_ERROR_TOO_MANY_DAYS(few) = "[count] days is too many (few)."
FIELD_ERROR_TOO_MANY_DAYS(many) = "[count] days is too many (many)."
FIELD_ERROR_TOO_MANY_DAYS(plural) = "[count] days is too many."

[% LOCALE fr %]

FIELD_ERROR_TOO_MANY_DAYS(one) = "Un jour est un trop grand nombre."
FIELD_ERROR_TOO_MANY_DAYS(plural) = "[count] jours est un trop grand nombre."

[% LOCALE xx %]

FIELD_ERROR_TOO_MANY_DAYS = "[count] [variant] xx too many days."

EOF

$field = My2::HTML::Form::Field::Days->new(name => 'days');

my $error_id = My2::HTML::Object::Errors::FIELD_ERROR_TOO_MANY_DAYS();

$field->error_id($error_id, { count => 0 });
is($field->error, '0 days is too many.', 'zero variant (en)');

$field->error_id($error_id, { count => 1 });

is($field->error, 'One day is too many.', 'one variant (en)');

$field->error_id($error_id, { count => 2 });

is($field->error, 'Two days is too many.', 'two variant (en)');

$field->error_id($error_id, { count => 3 });
is($field->error, '3 days is too many.', 'plural fallback variant (en)');

$field->error_id($error_id, { count => 3, variant => 'few' });
is($field->error, '3 days is too many (few).', 'few explicit variant (en)');

$field->error_id($error_id, { count => 3, variant => 'many' });
is($field->error, '3 days is too many (many).', 'many explicit variant (en)');

$field->locale('fr');

$field->error_id($error_id, { count => 0 });
is($field->error, '0 jours est un trop grand nombre.', 'zero variant (fr)');

$field->error_id($error_id, { count => 1 });

is($field->error, 'Un jour est un trop grand nombre.', 'one variant (fr)');

$field->error_id($error_id, { count => 2 });

is($field->error, '2 jours est un trop grand nombre.', 'two variant (fr)');

$field->error_id($error_id, { count => 3 });
is($field->error, '3 jours est un trop grand nombre.', 'plural fallback variant (fr)');

$field->error_id($error_id, { count => 3, variant => 'few' });
is($field->error, '3 jours est un trop grand nombre.', 'few explicit variant (fr)');

$field->error_id($error_id, { count => 3, variant => 'many' });
is($field->error, '3 jours est un trop grand nombre.', 'many explicit variant (fr)');

$field->locale('xx');

ok(!$field->localizer->localized_message_exists('FIELD_ERROR_TOO_MANY_DAYS', 'xx', 'zero'), 'localized_message_exists 1');

$field->error_id($error_id, { count => 0 });

is($field->error, '0  xx too many days.', 'zero variant (xx)');

$field->error_id($error_id, { count => 1 });

is($field->error, '1  xx too many days.', 'one variant (xx)');

$field->error_id($error_id, { count => 2 });

is($field->error, '2  xx too many days.', 'two variant (xx)');

$field->error_id($error_id, { count => 3 });
is($field->error, '3  xx too many days.', 'plural fallback variant (xx)');

$field->error_id($error_id, { count => 3, variant => 'few' });
is($field->error, '3 few xx too many days.', 'few explicit variant (xx)');

$field->error_id($error_id, { count => 3, variant => 'many' });
is($field->error, '3 many xx too many days.', 'many explicit variant (xx)');

($packages, $perl) = 
  Rose::HTML::Objects->make_private_library(in_memory => 1, 
                                            rename    => sub { s/Rose::H/MyH/ });

ok(MyHTML::Object->isa('Rose::HTML::Object'), 'rename sub 1');

END
{
  if($lib_dir && -d $lib_dir)
  {
    #rmtree($lib_dir);
  }
}
