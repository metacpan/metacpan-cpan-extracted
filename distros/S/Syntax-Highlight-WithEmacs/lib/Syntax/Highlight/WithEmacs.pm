# PODNAME: Syntax::Highlight::WithEmacs

use Moops;

=head1 NAME

Syntax::Highlight::WithEmacs - syntax-highlight source code using Emacs

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    my $hl = Syntax::Highlight::WithEmacs->new();
    my $html = $hl->htmlize_string(q{my $x = 42;}, 'pl');

    my $hl = Syntax::Highlight::WithEmacs->new(
        mode => 'css',
        use_client => 0,
        emacs_cmd => 'emacs24',
       );
    my ($pre_node, $css) = $hl->htmlize_string(q{my $x = 42;}, 'pl');

    print $hl->ansify_string(q{my $x = 42;}, 'pl');

=head1 DESCRIPTION

This module uses the Emacs script htmlize.el to provide syntax
highlighting the same way as your local Emacs does.

Care has been taken so that it works on the server, especially it has
been tested to work as part of a Movable Type CodeBeautifier plug-in
(but see L<MT::Plugin::BeautifierWithEmacs>).

Note that you I<do> need a working copy of Emacs including a working
set-up of htmlize. This module has been tested to work on GNU FSF
Emacs 23 and 24.

=head1 EXTENDED SETUP INSTRUCTIONS

htmlize for Emacs can be found on
L<http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el.cgi>. You need this
Emacs script, otherwise this module won't work.

You can download it to any place you like, for example
C<~/.emacs.d/elisp> and insert this code in your emacs start-up file:

    (add-to-list 'load-path "~/.emacs.d/elisp")

Check its operation from within Emacs using I<M-x> I<htmlize-buffer>.

To highlight B<Perl> code, the cperl mode by
L<JROCKWAY|http://search.cpan.org/~jrockway/> is highly recommended
(but you probably already know this if you are using Emacs). Please
download it from
L<https://github.com/jrockway/cperl-mode/tree/mx-declare>, the
mx-declare tree has support for the L<MooseX::Declare> syntaxes like
C<class>, C<method> and so on.

To turn the old perl-mode into cperl-mode (default on XEmacs), you can
use this elisp in your start-up file:

    (mapc (lambda (pair)
       (if (eq (cdr pair) 'perl-mode)
           (setcdr pair 'cperl-mode)))
     (append auto-mode-alist interpreter-mode-alist))

Other important modes for Emacs:

L<yaml-mode|https://github.com/yoshiki/yaml-mode>

    (autoload 'yaml-mode "yaml-mode"   "Simple mode to edit YAML." t)
    (add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))
    (add-to-list 'auto-mode-alist '("\\.yaml$" . yaml-mode))

L<js2-mode|https://github.com/mooz/js2-mode>

    (autoload 'js2-mode "js2-mode"   "Major mode for editing JavaScript code." t)
    (add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))

L<csharp-mode|http://code.google.com/p/csharpmode/>

    (autoload 'csharp-mode "csharp-mode" "Major mode for editing C# code." t)
    (setq auto-mode-alist
       (append '(("\\.cs$" . csharp-mode)) auto-mode-alist))

nxml-mode as default (on GNU FSF Emacs 23):

    (mapc (lambda (pair)
       (if (eq (cdr pair) 'xml-mode)
           (setcdr pair 'nxml-mode)))
     (append auto-mode-alist interpreter-mode-alist))

=cut

class Syntax::Highlight::WithEmacs 0.2 {
    use warnings;
    use File::Temp;
    use Carp;
    use XML::LibXML;
    use CSS::Tiny;
    use Hash::Util qw(lock_ref_keys_plus);
    use IPC::Run qw(run);
    use Term::ANSIColor;
    my $has_ccoxt; BEGIN { $has_ccoxt = eval q{
    use Convert::Color::XTerm;
    1}; }

    {
    	no warnings qw(redefine);
      # fix for FCGI environment
    	my $ipc_close_terminal = \&IPC::Run::close_terminal;
    	*::IPC::Run::close_terminal = sub {
    	    untie *STDIN; untie *STDOUT; untie *STDERR;
    	    $ipc_close_terminal->(@_);
    	};

      # fix for broken controlling terminal in IPC::Run :-{
	my $ipc_do_kid_n_exit = \&IPC::Run::_do_kid_and_exit;
	*::IPC::Run::_do_kid_and_exit = sub {
	    my $that = shift;
	    eval {
		if ( %{$that->{PTYS}} ) {
		    for ( keys %{$that->{PTYS}} ) {
			unless (${*{$that->{PTYS}->{$_}}}{_slave_controller}++) {
			    IPC::Run::Debug::_debug("Making a controller of ptty '$_'")
				    if IPC::Run::Debug::_debugging_details;
			    $that->{PTYS}->{$_}->make_slave_controlling_terminal;
			};
		    }
		}
	    };
	    $ipc_do_kid_n_exit->($that => @_);
	};
    }

=head1 METHODS

=head2 new

create new highlighter object. the following options are available:

=over

=item mode

designates the htmlize-output-type. Defaults to I<font>. Valid choices
usually include I<css> and I<inline-css>. See I<C-h> I<v>
I<htmlize-output-type> inside Emacs.

=item emacs_args

an array reference of additional parameters to pass to the
emacs(client) command. Defaults to the empty array. Possible uses
might be C<['-q']> or

    [-eval => qq((add-to-list 'load-path "$ENV{HOME}/.emacs.d/elisp"))]

to customise the load path, or

    [-eval => q((custom-set-variables '(frame-background-mode 'dark)))]

(or C<'light>) to set the colour scheme

=item emacs_cmd

command to start emacs. Defaults to C<emacs>

=item client_cmd

command to start the emacs client. Defaults to C<emacsclient>

=item term_spec

setting for the TERM environment variable when running emacs. Defaults
to C<xterm-256color>. Different values result in different set-ups for
the face properties, so the colours you get back from htmlize will be
different (use an eight colour set) if you use a value such as C<xterm>

=item htmlize_generate_hyperlinks

whether htmlize should add hyperlinks. as the default implementation
of C<htmlize-create-auto-links> frequently generates incorrect links
for me, this is disabled by default.

=item use_client

whether to use the emacs client. Defaults to true

=item server_name

the name of the emacs server to which the client will
connect. Defaults to "EmacsHtmlize(pid)_(counter)". You might want to
set this to the empty string to make it connect to your default
server. See also I<kill_server> below.

=item start_server

whether to start the emacs server on object creation time. Defaults to true

=item kill_server

whether to kill the emacs server during object destroy. Defaults to
true. You should definitely disable this if you have it connect to
your default server

=item ansi_opts

a hashref of additional options for the ansifier. see the
C<ansify_string> method.

=back

=cut

    my $servercnt = 0;
    has mode	     => (is => 'rw', default => 'font');
    has htmlize_generate_hyperlinks
	             => (is => 'rw', default => 0);
    has use_client   => (is => 'ro', default => 1);
    has server_name  => (is => 'ro', default => sub { ++$servercnt; "EmacsHtmlize$$\_$servercnt" });
    has start_server => (is => 'ro', default => 1, reader => '_start_server');
    has kill_server  => (is => 'ro', default => 1, reader => '_kill_server');
    has term_spec    => (is => 'ro', default => 'xterm-256color');
    has emacs_args   => (is => 'rw', default => sub{[]});
    has emacs_cmd    => (is => 'ro', default => 'emacs');
    has client_cmd   => (is => 'ro', default => 'emacsclient');
    has ansi_opts    => (is => 'rw', default => sub{+{}});

    method BUILD {
	$self->{lx} = XML::LibXML->new;
	$self->{lx}->recover(2);
	lock_ref_keys_plus($self,
			   # client module:
			   'made_server',
			   # ansify module:
			   'ansify_css', 'ansify_ccss', 'ansify_opts', '_ansify_italic'
			  );
	$self->start_server if $self->_start_server && $self->use_client;
    }

    method start_server {
	return if $self->{made_server};
	my ($cout, $cin, $cerr);
	my @cmd = ($self->emacs_cmd, @{$self->emacs_args},
		   '--daemon' . ($self->server_name ? '='.$self->server_name : ''));
	local $ENV{HOME} = (getpwuid $<)[7] unless $ENV{HOME};
	local $ENV{TERM} = $self->term_spec;
	run \@cmd, \$cin, \$cout, \$cerr;
	$self->{made_server} = 1;
    }

    method _client_cmd_args {
	($self->client_cmd, -a => '', ($self->server_name ? (-s => $self->server_name) : ()))
    }

    method run_htmlize($in, $out) {
	my $mode = $self->mode;
	for ($in, $out) {
	    unless (defined) { $_ = ''; next; }
	    s/(["\\])/\\$1/g;
	    $_ = qq{"$_"};
	}
	my $kill_command = $self->use_client ? '(delete-frame (selected-frame) t)' : '(kill-emacs)';
	my @cmd = $self->use_client ? $self->_client_cmd_args : $self->emacs_cmd;
	my @cmd_args = @{$self->emacs_args};
	@cmd_args = grep { !/^-q$/i } @cmd_args if $self->use_client;
	my $hyper = $self->htmlize_generate_hyperlinks ? 't' : 'nil';
	my @args = (@cmd, '-nw', @cmd_args,
		    -eval => qq((ignore-errors (require 'htmlize) (setq htmlize-generate-hyperlinks $hyper) (setq htmlize-output-type "$mode") (htmlize-file $in $out))),
		    -eval => $kill_command);
	local $ENV{HOME} = (getpwuid $<)[7] unless $ENV{HOME};
	local $ENV{TERM} = $self->term_spec;
	my ($tin, $tout, $err);
	run \@args, '<pty<', \$tin, '>pty>', \$tout, '2>', \$err;
	$self->{made_server} = $self->use_client;
    }

=head2 htmlize_file

run htmlize on a given filename. The major-mode emacs uses to highlight
it will be chosen by your own emacs configuration file, which is
usually by the file extension.

The following parameters are expected:

=over

=item I<$file>

input file to run htmlize on

=item I<$out>

output file to save html in. Can be omitted, in which case the output
file will be the input file with C<.html> appended

=back

this method does not return anything. You can process the generated
HTML file with any tool you like.

=cut

    method htmlize_file($file, $out = undef) {
	$self->run_htmlize($file, $out);
    }

=head2 htmlize_string

run htmlize on the given string. The following parameters are expected:

=over

=item I<$string>

a string with code to highlight.

=item I<$mode>

extension of the temporary file created. As most emacs configurations
choose major mode by extension, this will directly influence the file
mode used for highlighting.

=back

Note: the file name passed to htmlize matches
C<^EmacsHtmlize.*\.$mode$>. You can use this to configure mode rules
based on filename in your .gnu-emacs file.

This method B<returns> the highlighted code as a L<XML::LibXML::Node> and
the accompanying stylesheet as a L<CSS::Tiny> object. In scalar
context, only the HTML node is returned.

=cut

    method htmlize_string($string, $mode) {
	my $fh = File::Temp->new( TEMPLATE => 'EmacsHtmlize'.$$.'XXXXX', SUFFIX => ".$mode" );
	binmode $fh, ':utf8';
	print $fh $string;
	$fh->flush;
	my $filename = $fh->filename;
	my $no_unlink = -f "$filename.html";
	$self->htmlize_file($filename);
	unless (-f "$filename.html") {
	    croak "failed to create result file $filename.html";
	}
	my $doc = $self->{lx}->load_html(location => "$filename.html", encoding => 'UTF-8');
	unlink "$filename.html" unless $no_unlink;
	my ($html, $css) = ($doc->findnodes('/html/body/pre'), $doc->findnodes('/html/head/style'));
	if ($css) {
	    my $raw = $css->findvalue('.');
	    $raw =~ s/^\s*<!--(.*)-->\s*$/$1/s;
	    $css = CSS::Tiny->read_string($raw);
	    delete $css->{a};
	    delete $css->{'a:hover'};
	    $css->{pre} = delete $css->{body};
	}
	{
	    my $ch_fixup = $html->firstChild if $html;
	    $ch_fixup->replaceDataRegEx("^\n", '')
		if $ch_fixup && $ch_fixup->isa('XML::LibXML::Text');
	}
	$html->normalize;
	wantarray ? ($html, $css ? $css : ()) : $html
    }

=head2 ansify_string

run htmlize on the given string, like C<htmlize_string>, but return
the result as a string formatted with ANSI escape codes.

=over

=item I<$string>

a string with code to highlight.

=item I<$mode>

extension of the temporary file created. (see C<htmlize_string>)

=item I<%opts>

additional C<key =E<gt> value> pairs to configure the ansifier. the
defaults can be overwritten by setting a hashref in the C<ansi_opts>
property of the object. the following keys are possible:

=over

=item italic_as

attribute to use as italic, which can be given as a raw number to the
ANSI CSI m command or as string which is an alias as specified by the
L<Term::ANSIColor> module. popular choices include I<bold>,
I<underline>, I<reverse> and I<italic>. Defaults to I<reverse>. Note
that I<italic> was only added in Perl 5.18, so stick with

    italic_as => 3

for backwards compatibility!

=item css

an alternate CSS stylesheet to use for formatting, this can be a
L<CSS::Tiny> compatible hashref, CSS::Tiny compatible object or a
string to be fed to CSS::Tiny. defaults empty

=item color_depth

overwrite the colour depth that is used to render the ANSI escape
sequences. Defaults to 2**24. sensible other values would be 8, 16, or
256.

=item color_format

this sets the output format for colour escape sequences, which is not
quite standardised. the only current possible string value and also
the default is 'aix', which is xterm-compatible. however, if you
specify a coderef you can provide compatible output format for, say,
C<fbterm>.

=back

=back

=head2 COLOR_FORMAT ENCODER

you can give a coderef to the I<color_format> option of the ANSI
encoder to render colours to custom control codes. it takes the
following format:

    color_format => sub {
        my ($is_background, $index_or_r, $g, $b) = @_;
        my $color;

        if (defined $g) { $color = munge_rgb($index_or_r, $g, $b); }
        elsif (defined $index_or_r) { $color = munge_index($index_r); }
        else { $color = "default" }

        if ($is_background) { "control code to set background to $color" }
        elsif (defined $is_background) { "control code to set foreground to $color" }
        else { "control code to reset all colours" }
    }

=over

=item I<$is_background>

true if this is background colour

=item I<$index>

the colour index in 8, 16 or 256 colour palette (see I<color_depth>)

=item I<$r>, I<$g>, I<$b>

the colour values of the r-g-b channels as integer in the range of 0..255

=back

and returns the control codes for the requested colour spec

=cut

    my %ansi_default_opts;
    BEGIN {
	%ansi_default_opts = (
	    italic_as => 'reverse',
	    css => undef,
	    color_depth => 2**24,
	    color_format => 'aix',
	   );
    }
    method _colour_to_ansi($ct, $r, $g, $b) {
	my $cd = $self->{ansify_opts}{color_depth};
	if (!$has_ccoxt && $cd < 2**24 && $cd >= 8) {
	    croak "module Convert::Color::XTerm is required for color_depth $cd";
	}
	my $bg = $ct =~ /background/;
	my @cv;
	if ($cd >= 2**24) {
	    @cv = (2, $r, $g, $b);
	}
	elsif ($cd >= 256) {
	    @cv = (5, Convert::Color::RGB8->new($r, $g, $b)->as_xterm->index);
	}
	elsif ($cd >= 16) {
	    @cv = Convert::Color::RGB8->new($r, $g, $b)->as_xterm_16->index;
	}
	elsif ($cd >= 8) {
	    @cv = Convert::Color::RGB8->new($r, $g, $b)->as_xterm_8->index;
	}
	if (ref $self->{ansify_opts}{color_format}) {
	    shift @cv if @cv > 1;
	    $self->{ansify_opts}{color_format}->($bg, @cv);
	}
	elsif (@cv > 1) {
	    ($bg ? 48 : 38), @cv
	}
	elsif (@cv) {
	    (30 + $bg * 10 + int($cv[0]/8) * 60 + $cv[0]%8);
	}
	else {
	    return
	}
    }
    method _class_to_ansi(@class) {
	unless (@class) {
	    my $reset;

	    if (ref $self->{ansify_opts}{color_format}) {
		$reset .= join '', $self->{ansify_opts}{color_format}->();
	    };
	    $reset .= "\e[$Term::ANSIColor::ATTRIBUTES{reset}m";

	    return $reset
	}

	my (@simple, @ext_color);
	push @simple, $Term::ANSIColor::ATTRIBUTES{reset};

	my %seen;

	for my $class (reverse @class) {
	    my $css = $self->{ansify_ccss}{".$class"} // $self->{ansify_css}{".$class"};

	    push @simple, $Term::ANSIColor::ATTRIBUTES{underline}
		if exists $css->{'text-decoration'}  && !$seen{ul}++ && $css->{'text-decoration'} =~ /underline/i;

	    push @simple, $Term::ANSIColor::ATTRIBUTES{bold}
		if exists $css->{'font-weight'} && !$seen{b}++ && $css->{'font-weight'} =~ /bold/i;

	    push @simple, $self->{_ansify_italic}
		if exists $css->{'font-style'} && !$seen{em}++ && $css->{'font-style'} =~ /italic/i;

	    # where to store colour result?
	    my $scf = ref $self->{ansify_opts}{color_format} ? \@ext_color : \@simple;

	    for my $ct ('color', 'background-color') {
		if (exists $css->{$ct} && !$seen{$ct}++ && $css->{$ct} =~ /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i) {
		    my ($r, $g, $b) = map { hex $_ } ($1, $2, $3);
		    push @$scf, $self->_colour_to_ansi($ct, $r, $g, $b);
		}
	    }
	}

	my $format;

	my $simple = join ';', grep { length } @simple;
	if (length $simple) {
	    $format .= "\e[${simple}m";
	}
	if (@ext_color) {
	    $format .= join '', @ext_color;
	}

	$format
    }
    method _dump_node_ansi($node) {
	my $ret;
	for my $st (@{$self->_dump_node_marked($node)}) {
	    my ($classes, $text) = @$st;
	    my $format = $self->_class_to_ansi(split ' ', $classes);
	    $ret .= $format if defined $format;
	    $ret .= $text;
	}
	$ret
    }
    method ansify_string($string, $mode, %opts) {
	my %eff_opts = (%ansi_default_opts, %{$self->ansi_opts}, %opts);

	local $self->{htmlize_generate_hyperlinks} = 0;
	local $self->{mode} = 'css';

	my ($html_node, $css) = $self->htmlize_string($string, $mode);
	return unless $html_node;

	my $ccss = (ref $eff_opts{css} ? $eff_opts{css}
			: $eff_opts{css} ? CSS::Tiny->new($eff_opts{css}) : +{}) // +{};

	local $self->{ansify_css} = $css;
	local $self->{ansify_ccss} = $ccss;
	local $self->{ansify_opts} = \%eff_opts;
	local $self->{_ansify_italic} = $Term::ANSIColor::ATTRIBUTES{ $eff_opts{italic_as} } // $eff_opts{italic_as};

	$self->_dump_node_ansi($html_node->firstChild);
    }

=head2 marked_string

run htmlize on the given string, like C<htmlize_string>, but return an
arrayref of arrayrefs with class => string pairs similar to
L<Text::VimColor>'s C<marked> method.

=over

=item I<$string>

a string with code to highlight.

=item I<$mode>

extension of the temporary file created. (see C<htmlize_string>)

=back

Example:

    $hl->marked_string(q{my $x = 42;}, 'pl');
    # ==> result is like follows
    [ [ 'keyword',       'my'     ],
      [ '',              ' '      ],
      [ 'variable-name', '$x'     ],
      [ '',              ' = 42;' ] ];

note, it is B<not> compatible to Text::VimColor!

=cut

    method _dump_node_marked($node) {
	my @ret;
	while ($node) {
	    my (@class, $text);
	    my $tnode = $node;
	    while ($tnode->nodeType == XML_ELEMENT_NODE) {
		push @class, $tnode->getAttribute('class');
		$tnode = $tnode->firstChild;
	    }

	    if ($node->nodeType == XML_TEXT_NODE) {
		$text = $node->data;
		next unless length $text;
	    }
	    else {
		$text = $node->textContent;
	    }

	    push @ret, [(join ' ', grep { length } @class) => $text];
	}
	continue {
	    $node = $node->nextSibling;
	}
	\@ret
    }
    method marked_string($string, $mode) {
	local $self->{htmlize_generate_hyperlinks} = 0;
	local $self->{mode} = 'css';

	my $html_node = $self->htmlize_string($string, $mode);
	return unless $html_node;

    	$self->_dump_node_marked($html_node->firstChild);
    }

=head2 start_server

manually start the emacs server

=head2 kill_server

manually send the kill command to the emacs server.

=cut

    method kill_server {
	my @cmd = ($self->_client_cmd_args,
		   -eval => '(kill-emacs)');
	my ($cout, $cin, $cerr);
	local $ENV{HOME} = (getpwuid $<)[7] unless $ENV{HOME};
	local $ENV{TERM} = $self->term_spec;
	run \@cmd, \$cin, \$cout, \$cerr;
	$self->{made_server} = 0;
    }

    method DEMOLISH {
	$self->kill_server if $self->_kill_server && $self->{made_server}
    }
};

package Convert::Color::XTerm8 {
    my $base = 'Convert::Color::XTerm';
    if ($base->can('register_color_space')) {
	our @ISA = $base;
	__PACKAGE__->register_color_space('xterm_8');
	__PACKAGE__->register_palette(
	    enumerate_once => sub {
		map { __PACKAGE__->new($_) } 0..7
	    });
    }
};

package Convert::Color::XTerm16 {
    my $base = 'Convert::Color::XTerm';
    if ($base->can('register_color_space')) {
	our @ISA = $base;
	__PACKAGE__->register_color_space('xterm_16');
	__PACKAGE__->register_palette(
	    enumerate_once => sub {
		map { __PACKAGE__->new($_) } 0..15
	    });
    }
};

=head1 SEE ALSO

L<Text::EmacsColor>

This module wants to do the same but it does not work properly when
not using emacsclient, and it fails to include the colour definitions
because Emacs does not load those in batch mode.

Other Syntax::Highlight::* modules on CPAN.

L<Text::VimColor> which does the same using VIM.

=head1 AUTHOR

Ailin Nemui E<lt>ailin at devio dot usE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ailin Nemui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

    1
