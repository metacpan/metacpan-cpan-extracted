package CGI::Kwiki::I18N;
use strict;
use vars '@ISA';

my $init;
sub initialize {
    my ($self, $use_utf8) = @_;
    return if $init++;

    eval { require Locale::Maketext; 1 } or return;
    @ISA = ('Locale::Maketext');

    $self->_import(
        Class  => 'CGI::Kwiki',
        Style  => 'gettext',
        Export => 'gettext',
        Path   => substr(__FILE__, 0, -3),
        Decode => 1,
        Fail   => !$use_utf8,
    );
}

sub loc {
    my $self = shift;
    $self->initialize($] >= 5.008);
    gettext_lang();
    return gettext(@_);
}

sub _import {
    my ($class, %args) = @_;

    $args{Class}    ||= caller;
    $args{Style}    ||= 'maketext';
    $args{Export}   ||= 'loc';
    $args{Subclass} ||= 'I18N';

    my ($loc, $loc_lang) = $class->load_loc(%args);
    $loc ||= $class->default_loc(%args);

    no strict 'refs';
    *{caller(0) . "::$args{Export}"} = $loc if $args{Export};
    *{caller(0) . "::$args{Export}_lang"} = $loc_lang || sub { 1 };
}

my %Loc;
sub load_loc {
    my ($class, %args) = @_;
    return if $args{Fail};

    my $pkg = join('::', $args{Class}, $args{Subclass});
    return $Loc{$pkg} if exists $Loc{$pkg};

    eval { require File::Spec; 1 }		    or return;
    my $path = $args{Path} || $class->auto_path($args{Class})	or return;
    my $pattern = File::Spec->catfile($path, '*.[pm]o');
    my $decode = $args{Decode} || 0;

    $pattern =~ s{\\}{/}g; # to counter win32 paths

    eval "
	package $pkg;
	use base 'Locale::Maketext';
        %${pkg}::Lexicon = ( '_AUTO' => 1 );
	CGI::Kwiki::I18N::Lexicon->import({
	    '*'	=> [ Gettext => \$pattern ],
	    _decode => \$decode,
	});

	1;
    " or die $@;
    
    my $lh = eval { $pkg->get_handle } or return;
    my $style = lc($args{Style});
    if ($style eq 'maketext') {
	$Loc{$pkg} = $lh->can('maketext');
    }
    elsif ($style eq 'gettext') {
	$Loc{$pkg} = sub {
	    my $str = shift;
	    $str =~ s/[\~\[\]]/~$&/g;
	    $str =~ s{(^|[^%\\])%([A-Za-z#*]\w*)\(([^\)]*)\)}
		     {"$1\[$2,"._unescape($3)."]"}eg;
	    $str =~ s/(^|[^%\\])%(\d+|\*)/$1\[_$2]/g;
	    return $lh->maketext($str, @_);
	};
    }
    else {
	die "Unknown Style: $style";
    }

    return $Loc{$pkg}, sub {
	$lh = $pkg->get_handle(@_);
	$lh = $pkg->get_handle(@_);
    };
}

sub default_loc {
    my ($self, %args) = @_;
    my $style = lc($args{Style});
    if ($style eq 'maketext') {
	return sub {
	    my $str = shift;
	    $str =~ s/((?<!~)(?:~~)*)\[_(\d+)\]/$1%$2/g;
	    $str =~ s{((?<!~)(?:~~)*)\[([A-Za-z#*]\w*),([^\]]+)\]}
		     {"$1%$2("._escape($3).")"}eg;
	    $str =~ s/~([\[\]])/$1/g;
	    _default_gettext($str, @_);
	};
    }
    elsif ($style eq 'gettext') {
	return \&_default_gettext;
    }
    else {
	die "Unknown Style: $style";
    }
}

sub _default_gettext {
    my $str = shift;
    $str =~ s{
	%			# leading symbol
	(?:			# either one of
	    \d+			#   a digit, like %1
	    |			#     or
	    (\w+)\(		#   a function call -- 1
		%\d+		#	  with a digit 
		(?:		#     maybe followed
		    ,		#       by a comma
		    ([^),]*)	#       and a param -- 2
		)?		#     end maybe
		(?:		#     maybe followed
		    ,		#       by another comma
		    ([^),]*)	#       and a param -- 3
		)?		#     end maybe
		[^)]*		#     and other ignorable params
	    \)			#   closing function call
	)			# closing either one of
    }{
	my $digit = shift;
	$digit . (
	    $1 ? (
		($1 eq 'tense') ? (($2 eq ',present') ? 'ing' : 'ed') :
		($1 eq 'quant') ? ' ' . (($digit > 1) ? ($3 || "$2s") : $2) :
		''
	    ) : ''
	);
    }egx;
    return $str;
};

sub _escape {
    my $text = shift;
    $text =~ s/\b_(\d+)/%$1/;
    return $text;
}

sub _unescape {
    my $str = shift;
    $str =~ s/(^|,)%(\d+|\*)(,|$)/$1_$2$3/g;
    return $str;
}

sub auto_path {
    my $calldir = shift;
    $calldir =~ s#::#/#g;
    my $path = $INC{$calldir . '.pm'} or return;

    # Try absolute path name.
    if ($^O eq 'MacOS') {
	(my $malldir = $calldir) =~ tr#/#:#;
	$path =~ s#^(.*)$malldir\.pm\z#$1auto:$malldir:#s;
    } else {
	$path =~ s#^(.*)$calldir\.pm\z#$1auto/$calldir/#;
    }

    return $path if -d $path;

    # If that failed, try relative path with normal @INC searching.
    $path = "auto/$calldir/";
    foreach my $inc (@INC) {
	return "$inc/$path" if -d "$inc/$path";
    }

    return;
}

package CGI::Kwiki::I18N::Lexicon;
use strict;

my %Opts;
sub option { shift if ref($_[0]); $Opts{lc $_[0]} }
sub set_option { shift if ref($_[0]); $Opts{lc $_[0]} = $_[1] }

sub import {
    my $class = shift;
    return unless @_;

    my %entries;
    if (UNIVERSAL::isa($_[0], 'HASH')) {
	# a hashref with $lang as keys, [$format, $src ...] as values
	%entries = %{$_[0]};
    }
    elsif (@_ % 2) {
	%entries = ( '' => [ @_ ] );
    }

    # expand the wildcard entry
    if (my $wild_entry = delete $entries{'*'}) {
	while (my ($format, $src) = splice(@$wild_entry, 0, 2)) {
	    next if ref($src); # XXX: implement globbing for the 'Tie' backend

	    my $pattern = $src;
            $pattern =~ s/\*(?=[^*]+$)/\([-\\w]+\)/g or next;
	    $pattern =~ s/\*/.*?/g;

	    require File::Glob;
	    foreach my $file (File::Glob::bsd_glob($src)) {
		$file =~ /$pattern/ or next;
		push @{$entries{$1}}, ($format => $file) if $1;
	    }
	    delete $entries{$1}
		unless !defined($1)
		    or exists $entries{$1} and @{$entries{$1}};
	}
    }

    %Opts = ();
    foreach my $key (grep /^_/, keys %entries) {
	set_option(lc(substr($key, 1)) => delete($entries{$key}));
    }

    while (my ($lang, $entry) = each %entries) {
	my $export = caller;

	if (length $lang) {
	    # normalize language tag to Maketext's subclass convention
	    $lang = lc($lang);
	    $lang =~ s/-/_/g;
	    $export .= "::$lang";
	}

	my @pairs = @{$entry||[]} or die "no format specified";

	while (my ($format, $src) = splice(@pairs, 0, 2)) {
	    my @content = $class->lexicon_get($src, scalar caller, $lang);

	    no strict 'refs';

	    if (defined %{"$export\::Lexicon"}) {
		# be very careful not to pollute the possibly tied lexicon
		*{"$export\::Lexicon"} = {
		    %{"$export\::Lexicon"},
		    %{"$class\::$format"->parse(@content)},
		};
	    }
	    else {
		*{"$export\::Lexicon"} = "$class\::$format"->parse(@content);
	    }

	    push(@{"$export\::ISA"}, scalar caller) if length $lang;
	}
    }
}

sub lexicon_get {
    my ($class, $src, $caller, $lang) = @_;
    return unless defined $src;

    foreach my $type (qw(ARRAY HASH SCALAR GLOB), ref($src)) {
	next unless UNIVERSAL::isa($src, $type);

	my $method = 'lexicon_get_' . lc($type);
	die "cannot handle source $type for $src: no $method defined"
	    unless $class->can($method);

	return $class->$method($src, $caller, $lang);
    }

    # default handler
    return $class->lexicon_get_($src, $caller, $lang);
}

# assume filename - search path, open and return its contents
sub lexicon_get_ {
    my ($class, $src, $caller, $lang) = @_;

    require FileHandle;
    require File::Spec;

    my $fh = FileHandle->new;
    my @path = split('::', $caller);
    push @path, $lang if length $lang;

    $src = (grep { -e } map {
	my @subpath = @path[0..$_];
	map { File::Spec->catfile($_, @subpath, $src) } @INC;
    } -1 .. $#path)[-1] unless -e $src;

    die "cannot find $_[1] (called by $_[2]) in \@INC" unless -e $src;
    $fh->open($src) or die $!;
    binmode($fh);
    return <$fh>;
}

package CGI::Kwiki::I18N::Lexicon::Gettext;
use strict;

my ($InputEncoding, $OutputEncoding, $DoEncoding);

sub input_encoding { $InputEncoding };
sub output_encoding { $OutputEncoding };

sub parse {
    my $self = shift;
    my (%var, $key, @ret);
    my @metadata;

    $InputEncoding = $OutputEncoding = $DoEncoding = undef;

    # Check for magic string of MO files
    return parse_mo(join('', @_))
	if ($_[0] =~ /^\x95\x04\x12\xde/ or $_[0] =~ /^\xde\x12\x04\x95/);

    local $^W;	# no 'uninitialized' warnings, please.

    my $UseFuzzy = CGI::Kwiki::I18N::Lexicon::option('use_fuzzy');

    # Parse PO files
    foreach (@_) {
	/^(msgid|msgstr) +"(.*)" *$/	? do {	# leading strings
	    $var{$1} = $2;
	    $key = $1;
	} :

	/^"(.*)" *$/			? do {	# continued strings
	    $var{$key} .= $1;
	} :

	/^#, +(.*) *$/			? do {	# control variables
	    $var{$_} = 1 for split(/,\s+/, $1);
	} :

	/^ *$/ && %var			? do {	# interpolate string escapes
	    push @ret, (map transform($_), @var{'msgid', 'msgstr'})
		if length $var{msgstr} and !$var{fuzzy} or $UseFuzzy;
	    push @metadata, parse_metadata($var{msgstr})
		if $var{msgid} eq '';
	    %var = ();
	} : ();
    }

    push @ret, map { transform($_) } @var{'msgid', 'msgstr'}
	if length $var{msgstr};
    push @metadata, parse_metadata($var{msgstr})
	if $var{msgid} eq '';

    return {@metadata, @ret};
}

sub parse_metadata {
    return map {
	(/^([^\x00-\x1f\x80-\xff :=]+):\s*(.*)$/) ?
	    ($1 eq 'Content-Type') ? do {
		my $enc = $2;
		if ($enc =~ /\bcharset=\s*([-\w]+)/i) {
		    $InputEncoding = $1;
		    $OutputEncoding = CGI::Kwiki::I18N::Lexicon::option('encoding');
		    if ( CGI::Kwiki::I18N::Lexicon::option('decode') and
			(!$OutputEncoding or $InputEncoding ne $OutputEncoding)) {
			require Encode::compat if $] < 5.007001;
			require Encode;
			$DoEncoding = 1;
		    }
		}
		("__Content-Type", $enc);
	    } : ("__$1", $2)
	: ();
    } split(/\r*\n+\r*/, transform(pop));
}

sub transform {
    my $str = shift;

    $str = Encode::decode($InputEncoding, $str) if $DoEncoding and $InputEncoding;
    $str =~ s/\\([0x]..|c?.)/qq{"\\$1"}/eeg;
    $str =~ s/[\~\[\]]/~$&/g;
    $str =~ s/(?<![%\\])%([A-Za-z#*]\w*)\(([^\)]*)\)/"\[$1,".unescape($2)."]"/eg;
    $str =~ s/(?<![%\\])%(\d+|\*)/\[_$1]/g;
    $str = Encode::encode($OutputEncoding, $str) if $DoEncoding and $OutputEncoding;

    return $str;
}

sub unescape {
    my $str = shift;
    $str =~ s/(^|,)%(\d+|\*)(,|$)/$1_$2$3/g;
    return $str;
}

1;


### Assorted non-loc()ed localizable strings ###
# loc('HomePage')
# loc('RecentChanges')
# loc('Preferences')
# loc('Blog')
# loc('New Page Name')
# loc('BrianIngerson')
# loc('HomePage')
# loc('???')

# loc('KwikiAbout')
# loc('KwikiBackup')
# loc('KwikiBlog')
# loc('KwikiCustomization')
# loc('KwikiFeatures')
# loc('KwikiFit')
# loc('KwikiFormattingRules')
# loc('KwikiHelpIndex')
# loc('KwikiHotKeys')
# loc('KwikiInstallation')
# loc('KwikiKnownBugs')
# loc('KwikiLogoImage')
# loc('KwikiModPerl')
# loc('KwikiFastCGI')
# loc('KwikiNavigation')
# loc('KwikiPod')
# loc('KwikiPrivacy')
# loc('KwikiPrivatePage')
# loc('KwikiSisters')
# loc('KwikiSlideShow')
# loc('KwikiTodo')
# loc('KwikiUpgrading')
# loc('KwikiUserName')

# loc('KwikiModule')
# loc('KwikiDriverModule')
# loc('KwikiConfigModule')
# loc('KwikiConfigYamlModule')
# loc('KwikiFormatterModule')
# loc('KwikiDatabaseModule')
# loc('KwikiMetadataModule')
# loc('KwikiDisplayModule')
# loc('KwikiEditModule')
# loc('KwikiTemplateModule')
# loc('KwikiCgiModule')
# loc('KwikiCookieModule')
# loc('KwikiSearchModule')
# loc('KwikiChangesModule')
# loc('KwikiPrefsModule')
# loc('KwikiNewModule')
# loc('KwikiPagesModule')
# loc('KwikiStyleModule')
# loc('KwikiScriptsModule')
# loc('KwikiJavascriptModule')
# loc('KwikiSlidesModule')
