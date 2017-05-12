use strict;
use ExtUtils::MakeMaker;
use Config;

my(%macros, @miss, @defs);
my $cc_E_out = `$Config{cc} -E -I. utils/try.h` || 0; # May fail on some systems
if ($cc_E_out =~ / \b double \b .* \b sin \b .* \( .* \b double /x ) {
  # apparently, we can trust $cpp_out
  my ($sym);
  for $sym (qw(sinl logl cbrtl _cbrtl)) {
    next if $cc_E_out =~ / \b long \s+ double \b .* \b $sym \b .* \( .* \b long \s+ double /x;
    push @miss, $sym;
    warn(<<EOW), last if $sym =~ /^(sinl|logl)$/;
Looks like you do not have $sym() (is it BSD, and is BSD *that* broken?)...
  I will try to skip defining similar functions...
EOW
    warn <<EOW;
Looks like you do not have $sym()...
  I will try to define it in terms of powl()...
EOW
  }
  for $sym (qw(rint trunc)) {
    next if $cc_E_out =~ / \b double \b .* \b $sym \b .* \( .* \b double /x;
    warn <<EOW;
Looks like you do not have $sym() (is CC strictly C90 conformant?)...
  I will try to skip defining methods needing $sym()...
EOW
    push @miss, $sym;
  }
} else {
  push @miss, 'cc-E';		# Just in case; we do not expect it yet...
  warn "cc -E failed; I assume non-BSD, so not a completely broken long double...\n";
}

if ($^O =~ /win/i and $Config{cc} =~ /^cl\b/ and 4 == ($Config{longsize} || 0)
    and 8 == ($Config{longlongsize} || 0)) {	# Brain damaged cl v.12.00.8804
  push @defs, '-DMY_NEED_UQUAD_TO_DOUBLE';	# http://www.nntp.perl.org/group/perl.cpan.testers/2009/11/msg6068070.html
  push @miss, 'uquad2double';
}

$macros{WRITE_DRIVER_OPT} = "--miss=" . join ',', @miss if @miss;
	# Communicate to sinl.t:
open MISS, '>miss.miss' and print MISS "@miss" and close MISS;


# We do not include perl.h from handlers
push @defs, '-DMY_HAS_QUAD' if $Config{d_quad};
my $cbrtl_und = ((grep $_ eq 'cbrtl', @miss) ? '_' : '');
$cbrtl_und = 'powl_' if $cbrtl_und eq '_' and grep $_ eq '_cbrtl', @miss;

push @defs, "-Dmy_cbrtl=${cbrtl_und}cbrtl";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Numeric::LL_Array',
    VERSION_FROM      => 'LL_Array.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'LL_Array.pm', # retrieve abstract from module
       AUTHOR         => 'Ilya Zakharevich <ilyaz@cpan.org>') : ()),
    LIBS              => ['-lm'], # e.g., '-lm'
    DEFINE            => "@defs", # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    macro	      => \%macros,
    clean	      => { FILES => 'driver_0arg.h driver_1arg*.h driver_2arg*.h driver_ass.h table_1arg_2targs.h miss.miss' },
);

sub MY::postamble {
  ($[ < 5.006 ? "
PERLRUN = $^X

" : '') .
  '
AUTOGEN_C_FILES = driver_ass.h driver_0arg.h driver_1arg.h driver_2arg.h table_1arg_2targs.h

LL_Array$(OBJ_EXT) : driver_h.h signed_cmp_etc.h

driver_ass$(OBJ_EXT) :  driver_h.h signed_cmp_etc.h driver_ass.h  code_accessor.h

driver_0arg$(OBJ_EXT) : driver_h.h signed_cmp_etc.h driver_0arg.h code_0arg.h

driver_1arg$(OBJ_EXT) : driver_h.h signed_cmp_etc.h driver_1arg.h signed_cmp_etc.h code_1arg.h

driver_2arg$(OBJ_EXT) : driver_h.h signed_cmp_etc.h driver_2arg.h signed_cmp_etc.h code_2arg.h table_1arg_2targs.h

$(AUTOGEN_C_FILES): utils/write_driver.pl
	$(PERLRUN) utils/write_driver.pl $(WRITE_DRIVER_OPT)
';
}

