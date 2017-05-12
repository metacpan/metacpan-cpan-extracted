package PDF::FDF::Simple;

use strict;
use warnings;

use vars qw($VERSION $deferred_result_FDF_OPTIONS);
use Data::Dumper;
use Parse::RecDescent;
use IO::File;

use base 'Class::Accessor::Fast';
PDF::FDF::Simple->mk_accessors(qw(
                                     skip_undefined_fields
                                     filename
                                     content
                                     errmsg
                                     parser
                                     attribute_file
                                     attribute_ufile
                                     attribute_id
                                ));

$VERSION = '0.21';

#Parse::RecDescent environment variables: enable for Debugging
#$::RD_TRACE = 1;
#$::RD_HINT  = 1;

sub new {
  my $class = shift;

  my $parser;
  if ($ENV{PDF_FDF_SIMPLE_IGNORE_PRECOMPILED_GRAMMAR}) {
          # use external grammar file
          require File::ShareDir;
          my $grammar_file = File::ShareDir::module_file('PDF::FDF::Simple', 'grammar');
          open GRAMMAR_FILE, $grammar_file or die "Cannot open grammar file ".$grammar_file;
          local $/;
          my $grammar = <GRAMMAR_FILE>;
          $parser     = Parse::RecDescent->new($grammar);
  } else {
          # use precompiled grammar
          require PDF::FDF::Simple::Grammar;
          $parser = new PDF::FDF::Simple::Grammar;
  }

  my %DEFAULTS = (
                  errmsg                => '',
                  skip_undefined_fields => 0,
                  parser                => $parser
                 );
  # accept hashes or hash refs for backwards compatibility
  my %ARGS = ref($_[0]) =~ /HASH/ ? %{$_[0]} : @_;
  my $self = Class::Accessor::new($class, { %DEFAULTS, %ARGS });
  return $self;
}

sub _fdf_header {
  my $self = shift;

  my $string = "%FDF-1.2\n\n1 0 obj\n<<\n/FDF << /Fields 2 0 R";
  # /F
  if ($self->attribute_file){
    $string .= "/F (".$self->attribute_file.")";
  }
  # /UF
  if ($self->attribute_ufile){
    $string .= "/UF (".$self->attribute_ufile.")";
  }
  # /ID
  if ($self->attribute_id){
    $string .= "/ID[";
    $string .= $_ foreach @{$self->attribute_id};
    $string .= "]";
  }
  $string .= ">>\n>>\nendobj\n2 0 obj\n[";
  return $string;
}

sub _fdf_footer {
  my $self = shift;
  return <<__EOT__;
]
endobj
trailer
<<
/Root 1 0 R

>>
%%EOF
__EOT__
}

sub _quote {
  my $self = shift;
  my $str = shift;
  $str =~ s,\\,\\\\,g;
  $str =~ s,\(,\\(,g;
  $str =~ s,\),\\),g;
  $str =~ s,\n,\\r,gs;
  return $str;
}

sub _fdf_field_formatstr {
  my $self = shift;
  return "<< /T (%s) /V (%s) >>\n"
}

sub as_string {
  my $self = shift;
  my $fdf_string = $self->_fdf_header;
  foreach (sort keys %{$self->content}) {
    my $val = $self->content->{$_};
    if (not defined $val) {
      next if ($self->skip_undefined_fields);
      $val = '';
    }
    $fdf_string .= sprintf ($self->_fdf_field_formatstr,
                            $_,
                            $self->_quote($val));
  }
  $fdf_string .= $self->_fdf_footer;
  return $fdf_string;
}

sub save {
  my $self = shift;
  my $filename = shift || $self->filename;
  open (F, "> ".$filename) or do {
    $self->errmsg ('error: open file ' . $filename);
    return 0;
  };

  print F $self->as_string;
  close (F);

  $self->errmsg ('');
  return 1;
}

sub _read_fdf {
  my $self = shift;
  my $filecontent;

  # read file to be checked
  unless (open FH, "< ".$self->filename) {
    $self->errmsg ('error: could not read file ' . $self->filename);
    return undef;
  } else {
    local $/;
    $filecontent = <FH>;
  }
  close FH;
  $self->errmsg ('');
  return $filecontent;
}

sub _map_parser_output {
  my $self   = shift;
  my $output = shift;

  my $fdfcontent = {};
  foreach my $obj ( @$output ) {
    foreach my $contentblock ( @$obj ) {
      foreach my $keys (keys %$contentblock) {
        $fdfcontent->{$keys} = $contentblock->{$keys};
      }
    }
  }
  return $fdfcontent;
}

sub load {
  my $self = shift;
  my $filecontent = shift;

  # prepare content
  unless ($filecontent) {
    $filecontent = $self->_read_fdf;
    return undef unless $filecontent;
  }

  # parse
  my $output;
  {
      local $SIG{'__WARN__'} = sub { warn $_[0] unless $_[0] =~ /Deep recursion on subroutine/ };
      $output = $self->parser->startrule ($filecontent);
  }

  # take over parser results
  $self->attribute_file ($PDF::FDF::Simple::deferred_result_FDF_OPTIONS->{F});   # /F
  $self->attribute_ufile ($PDF::FDF::Simple::deferred_result_FDF_OPTIONS->{UF}); # /UF
  $self->attribute_id ($PDF::FDF::Simple::deferred_result_FDF_OPTIONS->{ID});    # /ID
  $self->content ($self->_map_parser_output ($output));
  $self->errmsg ("Corrupt FDF file!\n") unless $self->content;

  return $self->content;
}

1;
