package Padre::Plugin::Parrot;
BEGIN {
  $Padre::Plugin::Parrot::VERSION = '0.31';
}

# ABSTRACT: Experimental Padre plugin for Parrot

use 5.008;
use strict;
use warnings;

use Padre::Wx ();
use base 'Padre::Plugin';

my $parrot;

# TODO get documentation from parrot/src/ops/*.ops and parrot/docs/pdds/pdd19_pir.pod


sub padre_interfaces {
	return 'Padre::Plugin' => 0.47;
}

sub plugin_name {
	'Parrot';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'        => sub { $self->about },
		'Open Example' => sub { $self->open_example },
		'PIR 2 PBC'    => sub { $self->pir2pbc },

		#'Help'                                        => \&show_help,

		"Count characters using Perl5"                  => \&on_try_perl5,
		"Count characters using PIR in embedded Parrot" => \&on_try_pir,
	];
}

sub registered_documents {
	'application/x-pasm' => 'Padre::Document::PASM', 'application/x-pir' => 'Padre::Document::PIR',;
}

# TODO, Planning the syntax highlighting feature:
# -------------------------------
# let the user regiser
# mime-type, Path/to/language.pge, Name, Description?
# or
# mime-type, Path/to/language.exe, Name, Description?

# Though as this is only for personal use on the users own computer
# for now, we don't really need a description field but maybe the user
# wants to add comments.
# Name must be ASCII string without
# We can recognize if this is a .pge file or an executable
# (.exe on windows nothing on Unix) but we might also provide a check-box
# so the user can configure this.

# We ave this information in a database or config file
# We read this information at load time and based on this change the
# provided_highlighters and highlighting_mime_types functions
#
# With the module name being Padre::Plugin::HL::Name  (using the Name the user gave us)
# the module is virtual, only exists in memory

my @highlighters = (
	[ 'Padre::Document::PIR',  'PIR in Perl 5',  'PIR syntax highlighting with Perl 5 regular expressions' ],
	[ 'Padre::Document::PASM', 'PASM in Perl 5', 'PASM syntax highlighting with Perl 5 regular expressions' ],
	[ 'Padre::Plugin::Parrot', 'Parrot PGE',     'Using the PGE engine for highlighting' ],
);

my %highlighter_mimes = (
	'Padre::Document::PIR'  => ['application/x-pir'],
	'Padre::Document::PASM' => ['application/x-pasm'],
);

# [mime-type,    path-to-pbc-or-exe,  'NameWithoutSpace', 'Description']
my @config;
if ( $ENV{RAKUDO_DIR} ) {
	push @config, [ 'application/x-perl6', "$ENV{RAKUDO_DIR}/perl6.pbc", 'Perl6', 'Perl 6 via Parrot and perl6.pbc' ];
}
if ( $ENV{CARDINAL_DIR} ) {
	push @config,
		[
		'application/x-ruby', "$ENV{CARDINAL_DIR}/cardinal.pbc", 'Ruby',
		'Ruby via Cardinal on Parrot and cardinal.pbc'
		];
}

use Padre::Plugin::Parrot::HL;
foreach my $e (@config) {
	my ( $mime_type, $path, $name, $description ) = @$e;
	next if not -e $path;

	# TODO check other values as well

	my $pbc = ( $path =~ /\.pbc$/ ? 1 : 0 );
	my $module = 'Parrot::Plugin::HL::' . ( $pbc ? 'PBC::' : '' ) . $name;
	my $display_name = "Parrot/" . ( $pbc ? 'PBC' : 'EXE' ) . "/$name";
	{

		# create virtual namespace and colorize() function.
		# maybe I only need to create

		my $sub      = sub { return ( $pbc, $path ) };
		my $isa      = $module . '::ISA';
		my $function = $module . '::pbc_path';
		no strict 'refs';
		@$isa = ('Padre::Plugin::Parrot::HL');
		*{$function} = $sub;
	}
	push @highlighters, [ $module, $display_name, $description ];
	$highlighter_mimes{$module} = [$mime_type];
}

sub provided_highlighters {
	return @highlighters;
}

sub highlighting_mime_types {
	return %highlighter_mimes;
}

sub plugin_enable {
	my $self = shift;

	return if not $ENV{PARROT_DIR};

	return 1 if $main::parrot; # avoid crash when duplicate calling

	local @INC = (
		"$ENV{PARROT_DIR}/ext/Parrot-Embed/blib/lib",
		"$ENV{PARROT_DIR}/ext/Parrot-Embed/blib/arch",
		"$ENV{PARROT_DIR}/ext/Parrot-Embed/_build/lib",
		@INC
	);

	# for now we keep the parrot interpreter in a script-global
	# in $main as if we try to reload the Plugin the embedded parrot will
	# blow up. TODO: we should be able to shut down the Parrot interpreter
	# when the plugin is disabled.
	eval {
		require Parrot::Embed;
		$main::parrot = Parrot::Interpreter->new;
	};
	if ($@) {
		warn $@;
		return 1;
	}

	return 1;
}

sub on_try_perl5 {
	my ($main) = @_;

	my $doc = Padre::Current->document;
	my $str = "No file is open";
	if ($doc) {
		$str = "Number of characters in the current file: " . length( $doc->text_get );
	}

	Wx::MessageBox( "From Perl 5. $str", "Worksforme", Wx::wxOK | Wx::wxCENTRE, $main );
	return;
}

sub on_try_pir {
	my ($main) = @_;

	my $parrot = $main::parrot;
	if ( not $parrot ) {
		Wx::MessageBox( "Parrot is not available", "No luck", Wx::wxOK | Wx::wxCENTRE, $main );
		return;
	}

	my $code = <<END_PIR;
.sub on_try_pir
	.param string code

	.local int count
	count = length code

	.return( count )
.end
END_PIR

	my $eval = $parrot->compile($code);
	my $sub  = $parrot->find_global('on_try_pir');

	my $doc = Padre::Current->document;
	my $str = "No file is open";
	if ($doc) {
		my $pmc = $sub->invoke( 'PS', $doc->text_get );
		$str = "Number of characters in the current file: " . $pmc->get_string;
	}

	Wx::MessageBox( "From Parrot using PIR: $str", "Worksforme", Wx::wxOK | Wx::wxCENTRE, $main );
	return;
}

sub pir2pbc {
	my $main = Padre->ide->wx->main;
	my $doc  = Padre::Current->document;
	return if not $doc;
	my $filename = $doc->filename;
	return if not $filename or $filename !~ /\.pir$/i;
	$doc->pir2pbc;
}

sub open_example {
	require File::ShareDir;
	my $dir = File::Spec->catdir(
		File::ShareDir::dist_dir('Padre-Plugin-Parrot'),
		'examples'
	);

	my $main = Padre->ide->wx->main;
	return $main->open_file_dialog($dir);
}

sub about {
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription( "This plugin currently provides a naive syntax highlighting for PASM files\n"
			. "If you have Parrot compiled on your system it can also provide execution of\n"
			. "PASM files\n" );
	$about->SetVersion($Padre::Plugin::Parrot::VERSION);
	Wx::AboutBox($about);
	return;
}

sub show_help {
	my $main = Padre->ide->wx->main;

	if ( $ENV{PARROT_DIR} ) {
		my $path = File::Spec->catfile( $ENV{PARROT_DIR}, 'docs' );
		my $doc = Padre::Document->new;
		# to enable PodWeaver to work
		$doc->{original_content} = "\n=" . "head1 Parrot\n\nSome text\nL<\$PARROT_DIR/docs/intro.pod>\n=" . 'cut';

		$doc->set_mimetype('application/x-pod');
		$main->{help}->help($doc);
	} else {
		$main->{help}->help('Padre::Plugin::Parrot');
	}

	$main->{help}->SetFocus;
	$main->{help}->Show(1);
}

1;

#pasm:
# brace_highlight: 00ffff
# colors:
#  PASM_KEYWORD:     7f0000
#  PASM_REGISTER:    7f0044
#  PASM_LABEL:       aa007f
#  PASM_STRING:      00aa7f
#  PASM_COMMENT:     0000aa
#  PASM_POD:         0000ff
#
__END__
=pod

=head1 NAME

Padre::Plugin::Parrot - Experimental Padre plugin for Parrot

=head1 VERSION

version 0.31

=head1 SYNOPSIS

This Plugin provides several features

=over 4

=item *

Syntax highlighting via the PGE parse tree for languages using PCT - the Parrot Compiler Toolkit

=item *

Syntax highlighting of PIR and PASM files using Perl 5 regular expressions

=item *

Embedding of Parrot to allow extending Padre using languages running in Parrot

=back

After installation you need to enable the plugin via the Plugin Manager of Padre.
Once that is done there should be a menu option Plugins/Parrot with several submenus.

About is just some short explanation

The other menu options will count the number of characters in the current document
using the current Perl 5 interpreter or PASM running on top of Parrot.
Later we add other implementations running on top of Parrot.

The syntax highlighting provided by this module can be enabled on a perl file-type
(actually mime-type) base in the Edit/Preferences/Mime-types dialog.

=head1 NAME

=head1 INSTALLATION

This whole plugin is quite experimental. So is the documentation.
I hope the plugin can work with released and installed versions of Parrot as well but
I have never tried that. Let me outline how I install the dependencies.

It is quite simple though it has several steps in it.

Later we'll make this more simple.

I start with Rakudo (the implementation of Perl 6 on Parrot).

=head2 Install Rakudo

 $ cd $HOME
 $ mkdir work
 $ cd work
 $ git clone git://github.com/rakudo/rakudo.git
 $ cd rakudo
 $ perl Configure.pl --gen-parrot
 $ make

=head2 Configure env variables

Configure PARROT_DIR to point to the root of parrot
Configure RAKUDO_DIR to point to the directory where rakudo was checked out.
(I have these in the .bashrc)

 $ export PARROT_DIR=$HOME/work/rakudo/parrot
 $ export RAKUDO_DIR=$HOME/work/rakudo

Once this is done if you run Padre now you can enable Parrot/PGE highlighting of
Perl 6 files via the Edit/Preferences/Mime-types dialog.

=head2 Adding Cardinal (Ruby) highlighting

In order to support Ruby highlighting one needs to configure the CARDINAL_DIR
environment variable to point to the place where the cardinal.pbc can be located.

  $ cd $HOME/work
  $ git clone git://github.com/cardinal/cardinal.git
  $ export CARDINAL_DIR=$HOME/work/cardinal         # add this also to .bashrc
  $ cd $PARROD_DIR
  $ mkdir languages
  $ cd language
  $ ln -s $CARDINAL_DIR
  $ cd cardinal
  $ perl Configure.pl
  $ make

Once this is done if you run Padre now you can enable Parrot/PGE highlighting of
Ruby files via the Edit/Preferences/Mime-types dialog.

=head2 Embedding Parrot

=head3 Configure LD_LIBRARY_PATH (also in .bashrc)

 $ export LD_LIBRARY_PATH=$PARROT_DIR/blib/lib/

=head3 Build Parrot::Embed

  $ cd $PARROT_DIR/ext/Parrot-Embed/
  ./Build realclean
  perl Build.PL
  ./Build
  ./Build test

The test will give a warning like this, but will pass:

 Parrot VM: Can't stat no file here, code 2.
 error:imcc:syntax error, unexpected IDENTIFIER
	in file 'EVAL_2' line 1

Now if you run Padre and enable Padre::Plugin::Parrot
it will have an embedded Parrot interpreter that can run
code written in PIR. (See the Plugins/Parrot/Count Characters...)
menu options.

=head1 Related Tickets in Parrot

L<https://trac.parrot.org/parrot/ticket/77>
L<https://trac.parrot.org/parrot/ticket/74>
L<https://trac.parrot.org/parrot/ticket/76>
L<https://trac.parrot.org/parrot/ticket/79>
L<https://trac.parrot.org/parrot/ticket/77>

=head1 Adding more highlightings

In order to add more syntax highlighters one needs to

=over 4

=item 1)

make sure the relevant language can compile to a pbc file

=item 2)

add and entry to the @config variable.

=item 3)

add color codes to the missing tokens in L<Padre::Plugin::Parrot::ColorizeTask>

=back

=head1 TODO

=over 4

=item *

Eliminate the need for environment variables

=item *

Make the installations more simple, make sure it can work with released and installed versions of Parrot, Rakudo etc.

=item *

Allow the addition and configuration of more .pbc files (or executables) to @config (and keep it
in the Padre config database).

=item *

Separate the token lists for the various languages
L<Padre::Plugin::Parrot::ColorizeTask>

=item *

Automatically colorize any file type if it does not have a specified token to colors table.

=back

=head1 AUTHORS

=over 4

=item *

Gabor Szabo L<http://szabgab.com/>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Gabor Szabo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

