# $Id$
package MY;
use ExtUtils::MakeMaker;
use Config;

my ( $gencls, $i, $d, $l, $co) = ('gencls', '','','','');
my $severe = grep { $_ eq '--severe' } @ARGV;
@ARGV      = grep { $_ ne '--severe' } @ARGV;
eval { 
	require Prima::Config;
	$d  = $Prima::Config::Config{define};
	$i  = "$Prima::Config::Config{inc} -Iinclude -Iinclude/generic";
	$l  = $Prima::Config::Config{libs};
	$co = $Prima::Config::Config{cobjflag};
	$gencls = $Prima::Config::Config{gencls};
};
if ( $@) {
	warn "** Prima is required for build\n";
	if ( $severe) {
		unlink 'Makefile';
		exit 1;
	}
	$prima_failed = 1;
}

$prima_failed = 1 if @ARGV;

my @files = map {
	s/\.c$//;
	m/([^\\\/]*)$/;
	{ src => $_, name => $1 }
} <*.c>, <*/*.c>;

$_-> {is_class} = 1 for grep { -f $_-> {src} . '.cls' } @files;

# non-class c files may require h/inc from gencls build
@files = (
	(grep { $_-> {is_class}     } @files),
	(grep { not $_-> {is_class} } @files),
);

my $o = $Config{obj_ext};

sub post_initialize
{
	my $self = shift;
	my $t = $self->SUPER::post_initialize(@_);
	$t = <<PRE if $prima_failed;

ipa_init_state:
	$^X Makefile.PL --severe
	$Config{make}

PRE
	return $t;
}

sub postamble
{
	my $self = shift;
	my $t = $self->SUPER::postamble(@_);
	
	for ( @files) {
		next unless $_-> {is_class};
		my ( $n, $c) = ( $_-> {name}, $_-> {src});
	  	$t .= <<H

include/generic/$n.h: Makefile $c.cls
\t$gencls --inc --h $c.cls include/generic

$c$o: Makefile $c.c include/IPAsupp.h include/generic/$n.h include/generic/$n.inc

H
	}

	return $t;
}

sub c_o
{
	my $t = shift-> SUPER::c_o(@_);
	unless ( $t =~ /.c\$\(OBJ_EXT\)\s*:\n\t.*\$\*\$\(OBJ_EXT\)/ ) {
		$t =~ s/(\.c\$\(OBJ_EXT\)\s*:\n\t.*)/$1 $co\$*\$(OBJ_EXT)/;
	}
	return $t;
}

sub clean
{
	my $self = shift;
	my $t = $self->SUPER::clean(@_);
	$t .= "\t\$(RM_F) " . join( ' ', 
		map  { "include/generic/$_" } 
		map  { $_-> {name} . '.h', $_-> {name} . '.inc' } 
		grep { $_-> {is_class} }
		@files) .
		"\n";
	$t .= "\t\$(RM_F) " . join( ' ', 
		map { $_-> {src} . $o }
		@files);
	return $t;
}


WriteMakefile(
	NAME              => 'Prima::IPA',
	VERSION_FROM      => 'IPA.pm',
	MIN_PERL_VERSION  => '5.010',
	PREREQ_PM         => {
		'Prima'		=> 0,
	},
	ABSTRACT_FROM     => 'IPA.pm',
	AUTHOR            => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	LIBS              => [ $l ],
	DEFINE            => $d,
	INC               => $i,
	OBJECT            => join(' ', map { $_->{src} . '$(OBJ_EXT)' } @files),
	PM                => {
		# PM
		'IPA.pm'  	                          => '$(INST_LIBDIR)/IPA.pm',
		'Global/Region.pm'  	                  => '$(INST_LIBDIR)/IPA/Region.pm',
		( map  { ( "$_->{src}.pm"                 => "\$(INST_LIBDIR)/IPA/$_->{name}.pm" ) }
		grep { $_-> {is_class} }
		@files),
		# IPA HEADERS
		'include/IPAsupp.h'  	                  => '$(INST_LIBDIR)/IPA/CORE/IPAsupp.h',
		( map  { ( "include/generic/$_->{name}.h" => "\$(INST_LIBDIR)/IPA/CORE/generic/$_->{name}.h" ) }
		grep { $_-> {is_class} }
		@files),
		# CLASS HEADERS
		( map { ( $_                              => '$(INST_LIBDIR)/Prima/IPA/' . $_ ) }
		map  { glob "$_->{name}/*.h" }
		grep { $_-> {is_class} }
		@files),
	},
	EXE_FILES         => ['bin/iterm'],
	MAN3PODS          => {
		'IPA.pm'                                  => '$(INST_MAN3DIR)/Prima::IPA.$(MAN3EXT)',
		'Global/Region.pm'                        => '$(INST_MAN3DIR)/Prima::IPA::Region.$(MAN3EXT)',
		# MANPAGES
		( map { ( "$_->{src}.pm"                  => "\$(INST_MAN3DIR)/Prima::IPA::$_->{name}.\$(MAN3EXT)") } 
		grep { $_-> {is_class} }
		@files),
	},
	META_MERGE        => {
		resources => {
			repository => 'http://github.com/dk/IPA',
		},
		no_index  => {
			directory  => [qw(include t)],
			file       => [qw(Makefile.PL)],
		},
	},
);
