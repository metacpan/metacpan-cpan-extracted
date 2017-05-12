#!/usr/bin/perl -w

use strict;

require Test::More;

require 't/test-lib.pl';

if(have_db('sqlite_admin'))
{
  Test::More->import(tests => 219);
  #Test::More->import('no_plan');
}
else
{
  Test::More->import(skip_all => 'No SQLite');
}

use_ok('DateTime');
use_ok('DateTime::Duration');
use_ok('Time::Clock');
use_ok('Bit::Vector');
use_ok('Rose::DB::Object');

package My::DB::Object;
our @ISA = qw(Rose::DB::Object);
sub init_db { Rose::DB->new('sqlite') }
My::DB::Object->meta->table('rose_db_object_nonesuch');

package main;

use Rose::DB::Object::Util qw(set_state_saving unset_state_saving);

my $classes = My::DB::Object->meta->column_type_classes;

my $meta = My::DB::Object->meta;

my $DT    = DateTime->new(year => 2007, month => 12, day => 31, hour => 12, minute => 34, second => 56, nanosecond => 123456789);
my $Time  = Time::Clock->new('12:34:56');
my $Dur   = DateTime::Duration->new(years => 3);
my $Set   = [ 1, 2, 3 ];
my $Array = [ 4, 5, 6 ];
my $BV    = Bit::Vector->new_Dec(32, 123);

my %extra =
(
  enum     => { values => [ 'foo', 'bar' ] },
  bitfield => { bits => 32 },
  bits     => { bits => 32 },
);

my $i = 0;

foreach my $type (sort keys (%$classes)) #(qw(bits))#
{
  $i++;
  my %e = $extra{$type} ? %{$extra{$type}} : ();
  $meta->add_column("c$i" => { type => $type, %e });
}

foreach my $type (qw(char varchar))
{
  foreach my $mode (qw(fatal warn truncate))
  {
    $meta->add_column("overflow_${type}_$mode" => { type => $type, overflow => $mode, length => 4 });
  }
}

$meta->initialize;

my $o = My::DB::Object->new;

foreach my $type (qw(char varchar))
{
  my $column_name = "overflow_${type}_fatal";
  my $column = $o->meta->column($column_name);

  my $db = db_for_column_type($column->type);

  unless($db)
  {
    SKIP:
    {
      skip("db unavailable for $type tests", 5);
    }

    next;
  }

  $o->db($db);

  TRY:
  {
    local $@;
    eval { $column->parse_value($db, '12345') };
    like($@, qr/^My::DB::Object: Value for $column_name is too long.  Maximum length is 4 characters.  Value is 5 characters: 12345 /, $column_name);
  }

  $column_name = "overflow_${type}_warn";
  $column = $o->meta->column($column_name);

  WARN1:
  {
    my $warning = '';
    local $SIG{'__WARN__'} = sub { $warning .= join('', @_) };
    is($column->parse_value($db, '12345'), '1234', "$column_name 1");
    like($warning, qr/^My::DB::Object: Value for $column_name is too long.  Maximum length is 4 characters.  Value is 5 characters: 12345 /, "$column_name 2");
  }

  $column_name = "overflow_${type}_truncate";
  $column = $o->meta->column($column_name);

  WARN2:
  {
    my $warning = '';
    local $SIG{'__WARN__'} = sub { $warning .= join('', @_) };
    is($column->parse_value($db, '12345'), '1234', "$column_name 1");
    is($warning, '', "$column_name 2");
  }
}


foreach my $n (1 .. $i)
{
  my $col_name = "c$n";
  my $column   = $meta->column($col_name);
  my $type     = $column->type;

  my $method = method_for_column_type($type, $n);

  my $db = db_for_column_type($column->type);

  unless($db)
  {
    SKIP:
    {
      skip("db unavailable for $type tests", 2);
    }

    next;
  }

  $o->db($db);

  my $vn = 0;

  foreach my $input_value (input_values_for_column_type($type))
  {
    $o->$method($input_value);

    my $parsed_value = $o->$method();

    set_state_saving($o);
    my $formatted_value = $o->$method();
    unset_state_saving($o);

    is(massage_value(scalar $column->parse_value($db, $input_value)), massage_value($parsed_value), "$type parse_value $n.$vn");
    is(massage_value(scalar $column->format_value($db, $parsed_value)), massage_value($formatted_value), "$type format_value $n.$vn ($formatted_value)");

    $vn++;
  }
}

sub massage_value
{
  my($value) = shift;

  if(ref $value eq 'ARRAY')
  {
    return "@$value";
  }
  elsif(ref $value eq 'DateTime::Duration')
  {
    return join(':', map { $value->$_() } qw(years months weeks days hours minutes seconds nanoseconds));
  }

  return undef  unless(defined $value);

  # XXX: Trim off leading + sign that some versions of Math::BigInt seem to add
  $value =~ s/^\+//; 

  return "$value";
}

my %DB;

sub db_for_column_type
{
  my($type) = shift;

  if($type =~ / year to |^set$/)
  {
    return $DB{'informix'} ||= Rose::DB->new('informix');
  }
  elsif($type =~ /^(?:interval|chkpass)$/)
  {
    return $DB{'pg'} ||= Rose::DB->new('pg');
  }
  else
  {
    return $DB{'sqlite'} ||= Rose::DB->new('sqlite');
  }
}

sub method_for_column_type
{
  my($type, $i) = @_;

  if($type eq 'chkpass')
  {
    return "c${i}_encrypted";
  }

  return "c$i";
}

sub input_values_for_column_type
{
  my($type) = shift;

  if($type =~ /date|timestamp|epoch/)
  {
    return $DT, $DT->strftime('%Y-%m-%d %H:%M:%S.%N'), $DT->strftime('%m/%d/%Y %I:%M:%S.%N %p');
  }
  elsif($type eq 'time')
  {
    return $Time, $Time->as_string;
  }
  elsif($type eq 'interval')
  {
    return '3 years';
  }
  elsif($type eq 'enum')
  {
    return 'bar';
  }
  elsif($type eq 'set')
  {
    return $Set, '{1,2,3}';
  }
  elsif($type eq 'array')
  {
    return $Array, '{4,5,6}';
  }
  elsif($type =~ /^(?:bitfield|bits)/)
  {
    return $BV, $BV->to_Bin, $BV->to_Hex, '001111011';
  }
  elsif($type =~ /^bool/)
  {
    return 0, 'false', 'F', 1, 'true', 'T';
  }
  elsif($type eq 'chkpass')
  {
    return ':vOR7BujbRZSLP';
  }

  return 456;
}

sub value_for_column_type
{
  my($type) = shift;

  if($type =~ /date|timestamp|epoch/)
  {
    return $DT;
  }
  elsif($type eq 'time')
  {
    return $Time;
  }
  elsif($type eq 'interval')
  {
    return $Dur;
  }
  elsif($type eq 'enum')
  {
    return 'bar';
  }
  elsif($type eq 'set')
  {
    return $Set;
  }
  elsif($type eq 'array')
  {
    return $Array;
  }
  elsif($type =~ /^(?:bitfield|bits)/)
  {
    return $BV;
  }
  elsif($type =~ /^bool/)
  {
    return 0;
  }
  elsif($type eq 'chkpass')
  {
    return ':vOR7BujbRZSLP';
  }

  return 456;
}
