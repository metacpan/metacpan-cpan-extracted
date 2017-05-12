#!/usr/bin/env perl

use strict;
use warnings;
use utf8::all;

my $project_root;
my $corpus;
my $template_root;
my $output_root;

BEGIN {
  use Path::Tiny;
  use FindBin;
  $project_root  = path($FindBin::Bin)->parent;
  $corpus        = $project_root->child('corpus');
  $template_root = $corpus->child('template');
  $output_root   = $project_root->child('t')->child('02-String-Sections');
}

use Template::Alloy;
use lib $project_root->child('lib')->stringify;

my $targets = [
  {
    template   => 'parse_filehandle.tpl',
    target_dir => $output_root->child('parse_filehandles'),
  },
  {
    template   => 'parse_list.tpl',
    target_dir => $output_root->child('parse_list'),
  }
];
use String::Sections;
use Data::Dump qw(pp);
my $parser = String::Sections->new();

for my $target ( @{$targets} ) {
  *STDOUT->printf( "* Processing target %s into %s\n", $target->{template}, $target->{target_dir} );
  my $t = Template::Alloy->new(
    SYNTAX   => 'tt3',
    filename => $target->{template},
    path     => [ $template_root->stringify ],
  );

  for my $file ( $corpus->child('template_body')->children ) {

    my $filename = $file->basename;
    $filename =~ s/[.][^.]+$/.t/;
    *STDOUT->printf( "  %30s → %-30s\n", $file->basename, $filename );
    my $output_file = $target->{target_dir}->child($filename);
    my $output_fh   = $output_file->openw();

    my $data = $parser->load_filehandle( $file->openr() );
    $t->param( { map { $_, ${ $data->section($_) } } $data->section_names } );
    $t->output( print_to => $output_fh );
    for my $name ( $data->section_names ) {
      delete $t->{_var}->{$name};
    }
    1;
  }
}
