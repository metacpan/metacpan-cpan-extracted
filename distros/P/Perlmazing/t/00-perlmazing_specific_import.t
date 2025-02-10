use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More;;

# test default
{
  package test::one;
  use Perlmazing;
  use Test::More;
  my $exportable_functions;
  for my $export_tag (sort keys %Perlmazing::EXPORT_TAGS) {
    for my $function_name (@{$Perlmazing::EXPORT_TAGS{$export_tag}}) {
      $exportable_functions->{$function_name} = 0;
    }
  }
  my @default = @{$Perlmazing::EXPORT_TAGS{default}};
  map {$exportable_functions->{$_} = 1} @default;
  
  for my $function (sort keys %$exportable_functions) {
    no strict 'refs';
    my $exists = exists ${__PACKAGE__.'::'}{$function};
    if ($exportable_functions->{$function}) {
      is $exists, 1, __PACKAGE__." - Function succesfully imported: $function";
    } else {
      isnt $exists, 1, __PACKAGE__." - Function successfully NOT imported: $function";
    }
  }
}
# default menus one
{
  package test::two;
  use Perlmazing qw(!pl);
  use Test::More;
  my $exportable_functions;
  for my $export_tag (sort keys %Perlmazing::EXPORT_TAGS) {
    for my $function_name (@{$Perlmazing::EXPORT_TAGS{$export_tag}}) {
      $exportable_functions->{$function_name} = 0;
    }
  }
  my @default = @{$Perlmazing::EXPORT_TAGS{default}};
  map {$exportable_functions->{$_} = 1} @default;
  $exportable_functions->{pl} = 0;
  
  for my $function (sort keys %$exportable_functions) {
    no strict 'refs';
    my $exists = exists ${__PACKAGE__.'::'}{$function};
    if ($exportable_functions->{$function}) {
      is $exists, 1, __PACKAGE__." - Function succesfully imported: $function";
    } else {
      isnt $exists, 1, __PACKAGE__." - Function successfully NOT imported: $function";
    }
  }
}
# none
{
  package test::three;
  use Perlmazing qw();
  use Test::More;
  my $exportable_functions;
  for my $export_tag (sort keys %Perlmazing::EXPORT_TAGS) {
    for my $function_name (@{$Perlmazing::EXPORT_TAGS{$export_tag}}) {
      $exportable_functions->{$function_name} = 0;
    }
  }
  
  for my $function (sort keys %$exportable_functions) {
    no strict 'refs';
    my $exists = exists ${__PACKAGE__.'::'}{$function};
    if ($exportable_functions->{$function}) {
      is $exists, 1, __PACKAGE__." - Function succesfully imported: $function";
    } else {
      isnt $exists, 1, __PACKAGE__." - Function successfully NOT imported: $function";
    }
  }
}
# default plus an import tag
{
  package test::four;
  use Perlmazing qw(:string);
  use Test::More;
  my $exportable_functions;
  for my $export_tag (sort keys %Perlmazing::EXPORT_TAGS) {
    for my $function_name (@{$Perlmazing::EXPORT_TAGS{$export_tag}}) {
      $exportable_functions->{$function_name} = 0;
    }
  }
  my @default = @{$Perlmazing::EXPORT_TAGS{default}};
  my @string = @{$Perlmazing::EXPORT_TAGS{string}};
  map {$exportable_functions->{$_} = 1} @default;
  map {$exportable_functions->{$_} = 1} @string;
  
  for my $function (sort keys %$exportable_functions) {
    no strict 'refs';
    my $exists = exists ${__PACKAGE__.'::'}{$function};
    if ($exportable_functions->{$function}) {
      is $exists, 1, __PACKAGE__." - Function succesfully imported: $function";
    } else {
      isnt $exists, 1, __PACKAGE__." - Function successfully NOT imported: $function";
    }
  }
}
# default plus an import tag minus one default minus one from import tag
{
  package test::five;
  use Perlmazing qw(!pl :string !to_string);
  use Test::More;
  my $exportable_functions;
  for my $export_tag (sort keys %Perlmazing::EXPORT_TAGS) {
    for my $function_name (@{$Perlmazing::EXPORT_TAGS{$export_tag}}) {
      $exportable_functions->{$function_name} = 0;
    }
  }
  my @default = @{$Perlmazing::EXPORT_TAGS{default}};
  my @string = @{$Perlmazing::EXPORT_TAGS{string}};
  map {$exportable_functions->{$_} = 1} @default;
  map {$exportable_functions->{$_} = 1} @string;
  $exportable_functions->{pl} = 0;
  $exportable_functions->{to_string} = 0;
  
  for my $function (sort keys %$exportable_functions) {
    no strict 'refs';
    my $exists = exists ${__PACKAGE__.'::'}{$function};
    if ($exportable_functions->{$function}) {
      is $exists, 1, __PACKAGE__." - Function succesfully imported: $function";
    } else {
      isnt $exists, 1, __PACKAGE__." - Function successfully NOT imported: $function";
    }
  }
}
# no default plus an import tag
{
  package test::six;
  use Perlmazing qw(!:default :string);
  use Test::More;
  my $exportable_functions;
  for my $export_tag (sort keys %Perlmazing::EXPORT_TAGS) {
    for my $function_name (@{$Perlmazing::EXPORT_TAGS{$export_tag}}) {
      $exportable_functions->{$function_name} = 0;
    }
  }
  my @string = @{$Perlmazing::EXPORT_TAGS{string}};
  map {$exportable_functions->{$_} = 1} @string;
  
  for my $function (sort keys %$exportable_functions) {
    no strict 'refs';
    my $exists = exists ${__PACKAGE__.'::'}{$function};
    if ($exportable_functions->{$function}) {
      is $exists, 1, __PACKAGE__." - Function succesfully imported: $function";
    } else {
      isnt $exists, 1, __PACKAGE__." - Function successfully NOT imported: $function";
    }
  }
}

done_testing();
