use strict;
use warnings;

# The functions where we specify manual implementations or prototypes
# These could also be read from Modern.xs, later maybe
my @manual_list = qw(
  glGetString
  glShaderSource_p
);

my %manual;
@manual{@manual_list} = ( 1 ) x @manual_list;

sub is_manual { $manual{$_[0]} }
sub manual_list { @manual_list }

sub slurp {
    my $filename = $_[0];
    open my $old_fh, '<:raw', $filename
      or die "Couldn't read '$filename': $!";
    join '', <$old_fh>;
}

sub save_file {
    my ( $filename, $new ) = @_;
    my $old = -e $filename ? slurp( $filename ) : "";
    if ( $new ne $old ) {
        print "Saving new version of $filename\n";
        open my $fh, '>:raw', $filename
          or die "Couldn't write new version of '$filename': $!";
        print $fh $new;
    }
}

sub bindings {
  die "list context only" if !wantarray;
  my ($name, $s) = @_;
  my $avail_check = ($s->{glewtype} eq 'fun' && $s->{glewImpl})
    ? "  OGLM_AVAIL_CHECK($s->{glewImpl}, $name)\n"
    : "";
  my @argdata = @{$s->{argdata} || []};
  my $callarg_list = $s->{glewtype} eq 'var' ? "" : "(@{[ join ', ', map $_->[0], @argdata ]})";
  my $thistype = $s->{restype};
  my $c_suffix = $s->{has_ptr_arg} ? '_c' : '';
  my $i = 0;
  my %default = (
    binding_name => $name . $c_suffix,
    xs_rettype => $s->{restype},
    xs_args => join(', ', map $_->[0], @argdata),
    xs_argdecls => join('', map "  $_->[1]$_->[0];\n", @argdata),
    aliases => !$s->{aliases} ? "" : "ALIAS:\n".join('', map "  $_$c_suffix = ".++$i."\n", sort keys %{$s->{aliases}}),
    xs_code => "CODE:\n",
    error_check => ($name eq "glGetError") ? "" : "OGLM_CHECK_ERR($name, )",
    avail_check => $avail_check,
    beforecall => '',
    retcap => ($thistype eq 'void' ? '' : 'RETVAL = '),
    callarg_list => $callarg_list,
    error_check2 => ($name eq "glGetError") ? "" : "OGLM_CHECK_ERR($name, )",
    aftercall => '',
    retout => ($thistype eq 'void' ? '' : "\nOUTPUT:\n  RETVAL"),
  );
  my @ret = \%default;
  return @ret if !$s->{has_ptr_arg};
  if ($name =~ /^gl(?:Gen|Create)/ && @argdata == 2 && $s->{restype} eq 'void' ) {
    $i = 0;
    push @ret, {
      %default,
      binding_name => $name . '_p',
      xs_args => join(', ', map $_->[0], $argdata[0]),
      xs_argdecls => join('', map "  $_->[1]$_->[0];\n", $argdata[0]),
      aliases => !$s->{aliases} ? "" : "ALIAS:\n".join('', map "  ${_}_p = ".++$i."\n", sort keys %{$s->{aliases}}),
      xs_code => "PPCODE:\n",
      beforecall => "  OGLM_GEN_SETUP($name, $argdata[0][0], $argdata[1][0])\n",
      error_check2 => "OGLM_CHECK_ERR($name, free($argdata[1][0]))",
      aftercall => "\n  OGLM_GEN_FINISH($argdata[0][0], $argdata[1][0])",
    };
  }
  if ($name =~ /^glDelete/ and @argdata == 2 and $argdata[1][1] =~ /^\s*const\s+GLuint\s*\*\s*$/) {
    $i = 0;
    push @ret, {
      %default,
      binding_name => $name . '_p',
      xs_args => '...',
      xs_argdecls => '',
      aliases => !$s->{aliases} ? "" : "ALIAS:\n".join('', map "  ${_}_p = ".++$i."\n", sort keys %{$s->{aliases}}),
      beforecall => "  GLsizei $argdata[0][0] = items;\n  OGLM_DELETE_SETUP($name, items, $argdata[1][0])\n",
      error_check2 => "OGLM_CHECK_ERR($name, free($argdata[1][0]))",
      aftercall => "\n  OGLM_DELETE_FINISH($argdata[1][0])",
    };
  }
  @ret;
}

1;
