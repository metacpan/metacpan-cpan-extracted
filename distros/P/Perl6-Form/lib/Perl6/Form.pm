package Perl6::Form;
use 5.008;

our $VERSION = '0.090';

use Perl6::Export;
use Scalar::Util qw( readonly );
use List::Util   qw( max min first );
use Carp;
use charnames ':full';

my %caller_opts;

sub fatal {
    croak @_, "\nin call to &form";
}

sub defined_or_space {
    return " " if !defined $_[0] || length $_[0] == 0;
    return $_[0];
}

sub boolean {
    return $_[0] ? 1 : 0;
}

sub pattern {
    return $_[0] if ref $_[0] eq 'Regexp';
    return $_[0] ? qr/(?=)/ : qr/(?!)/;
}

sub code {
    my ($newval, $name ) = @_;
    my $type = ref($newval) || "'$newval'";
    fatal "Value for '$name' option must be code reference (not $type)"
            unless $type eq 'CODE';
    return $newval;
}

my %std_one = (
    '=' => '{=[{1}[=}',
    '_' => '{_[{1}[_}',
);

sub one_char {
    my ($newval, undef, $opts ) = @_;
    $newval = [ $newval ] unless ref $newval eq 'ARRAY';
    for (@$newval) {
        fatal "Value for 'single' option must be single character (not '$_')"
            if length() != 1;
        $opts->{field} =
            user_def([qr/\Q$_\E/, $std_one{$_}||'{[{1}[}'], 'single', $opts);
    }
    return;
}

sub layout_word {
    fatal "Value for layout option must be 'across', 'down', 'balanced', ",
          "or 'tabular\n(not '$_[0]')"
            unless $_[0] =~ /^(across|down|balanced|tabular)$/;
    return $_[0];
}

sub pos_integer {
    fatal "Value for '$_[1]' option must be positive integer (not $_[0])"
            unless int($_[0]) eq $_[0] && $_[0] > 0;
    return $_[0];
}

sub strings_or_undef {
    my ($val, $name) = @_;
    my $type = ref $val;
    if (!defined $val) { $val = [] }
    elsif (!$type)     { $val = [ "$val" ] }
    fatal "Value for '$name' option must be string, array of strings, or undef (not \L$type\E)"
            unless ref $val eq 'ARRAY';
    return $val;
}

my $unlimited = ~0>>1;          # Ersatz infinity

sub height_vals {
    my ($vals) = @_;
    my $type = ref $vals;
    if (!defined $vals)      { $vals = {min=>0,     max=>$unlimited} }
    elsif (!$type && $vals eq 'minimal')
                             { $vals = {min=>0, max=>$unlimited, minimal=>1} }
    elsif (!$type)           { $vals = {min=>$vals, max=>$vals}     }
    elsif ($type eq 'HASH')  { $vals->{min}||=0;
                               defined $vals->{max} or $vals->{max}=$unlimited;
                             }
    fatal "Values for height option must be positive integers (not $_[0])"
                unless ref $vals eq 'HASH'
                    && !grep {int($vals->{$_}) ne $vals->{$_}} qw(min max);
    return $vals;
}

my %nothing = map {$_=>sub{""}} qw(first even odd other);

sub std_body {
    my ($rows, $fill, $opt) = @_;
    join("", @$rows, @$fill);
}
my %std_body = (other =>\&std_body);

my %def_page = (
    length => $unlimited,
    width  => 78,
    header => \%nothing,        # Args: ($opts)
    footer => \%nothing,        # Args: ($opts)
    body   => \%std_body,       # Args: ($body_rows, $body_len, $opts)
    feed   => \%nothing,        # Args: ($opts)
    number => undef,
);

sub form_body {
    my ($format) = @_;
    $format = '{[{*}[}' unless defined $format;
    return sub {
        my ($rows, $fill, $opt) = @_;
        my %form_opts = ( page=>{width => $opt->{page}{width}} );
        @{$form_opts{height}}{qw(min max)} = (@$rows+@$fill) x 2
            unless $opt->{page}{length} == $unlimited;
        return form(\%form_opts, $format, $rows);
    }
}

sub hashify {
    my ($what, $val, $default_undef, $default_val) = @_;
    if (!defined $val) {
        return { other => $default_undef};
    }
    if (!ref $val) {
        return { other => $default_val->($val) };
    }
    if (ref $val eq 'CODE') {
        return { other => $val };
    }
    if (ref $val eq 'HASH') {
        fatal "Invalid key for $what: '$_'"
            for grep { !/^(first|last|even|odd|other)$/ } keys %$val;
        my %hash;
        for (keys %$val) {
            if (!ref $val->{$_}) {
                $hash{$_} = $default_val->($val->{$_})
            }
            elsif (ref $val->{$_} ne 'CODE') {
                fatal "Value for $what '$_' must be string or subroutine";
            }
            else {
                $hash{$_} = $val->{$_};
            }
        }
        return \%hash;
    }
    fatal "Value for $what must be string, subroutine, or hash";
}

sub page_hash {
    my ($h, undef, $opts) = @_;
    fatal "Value for 'page' option must be hash reference (not $_)"
        for grep $_ ne 'HASH', ref $h;
    $h = { %{$opts->{page}}, %$h };
    fatal "Unknown page sub-option ('$_')"
        for grep {!exists $def_page{$_}} keys %$h;
    fatal "Page $_ must be greater than zero"
        for grep $h->{$_} <= 0, qw(length width);
    $h->{body} =
        hashify("body preprocessor", $h->{body}, \&std_body, \&form_body);
    for (qw( header footer feed )) {
        $h->{$_} = hashify($_, $h->{$_}, sub{""}, sub{my($str)=@_; sub{$str}});
    }
    return $h;
}

sub filehandle {
    fatal "Value for 'out' option must be filehandle (not '$_')"
            for grep {$_ ne 'GLOB' } ref $_[0];
    return $_[0];
}

sub user_def {
    my ($spec, $name, $opts) = @_;
    my $type = ref $spec;
    fatal "Value of 'field' option must be an array of pairs or a hash (not ",
          $type||"'$spec'", ")"
                unless $type =~ /^(ARRAY|HASH)$/;
    if ($type eq 'ARRAY') {
        fatal "Missing value for last user-defined field ('$spec->[-1]')"
            if @$spec % 2;
    }
    else {
        $spec = [%$spec];
    }
    my @from = @{$opts->{field}{from}||=[]};
    my @to   = @{$opts->{field}{to}||=[]};
    my $count = @from;
    for (my $i=0; $i<@$spec; $i+=2, $count++) {
        my ($pat, $fld) = @{$spec}[$i,$i+1];
        push @from, "$pat(?{$count})";
        push @to,   (ref $fld eq 'CODE' ? $fld : sub{$fld});
    }
    return {from=>\@from, to=>\@to};
}

my %std_opt = (
    out     => { set => \&filehandle,       def => \*STDOUT,            },
    ws      => { set => \&pattern,          def => undef,               },
    fill    => { set => \&defined_or_space, def => " ",                 },
    lfill   => { set => \&defined_or_space, def => undef,               },
    rfill   => { set => \&defined_or_space, def => undef,               },
    hfill   => { set => \&defined_or_space, def => undef,               },
    tfill   => { set => \&defined_or_space, def => undef,               },
    bfill   => { set => \&defined_or_space, def => undef,               },
    vfill   => { set => \&defined_or_space, def => undef,               },
    single  => { set => \&one_char,         def => undef,               },
    field   => { set => \&user_def,         def => {from=>[],to=>[]}    },
    bullet  => { set => \&strings_or_undef, def => []                   },
    height  => { set => \&height_vals,      def => {min=>0, max=>$unlimited} },
    layout  => { set => \&layout_word,      def => 'balanced',          },
    break   => { set => \&code,             def => break_at('-'),       },
    page    => { set => \&page_hash,        def => {%def_page},         },
    under   => { set => sub {"$_[0]"},      def => undef                },
    interleave  => { set => \&boolean,      def => 0                    },
    untrimmed   => { set => \&boolean,      def => 0,                   },
    locale      => { set => \&boolean,      def => 0,                   },
);

my %def_opts = map {$_=>$std_opt{$_}{def}}  keys %std_opt;

sub get_locale_vals {   # args: $dec_mark, $thou_sep, $thou_group
    use POSIX;
    $lconv = POSIX::localeconv();
    $_[0] = exists $lconv->{decimal_point} ? $lconv->{decimal_point} : "?";
    $_[1] = exists $lconv->{thousands_sep} ? $lconv->{thousands_sep} : "";
    $_[2] = exists $lconv->{grouping} ? [unpack "c*", $lconv->{grouping}] : [0];
}

my %std_literal = (
    break   => \&break_lit,
    literal => 1,
    vjust   => \&jverlit,
    hjust   => \&jhorlit,
);

sub update(\%\%;$) {
    my ($old, $new, $croak) = @_;
    my @bad;
    for my $opt (keys %$new) {
        my $std = $std_opt{$opt};
        push @bad, "Unknown option: $opt=>'$new->{$opt}" and next unless $std;
        $old->{$opt} = $std->{set}->($new->{$opt}, $opt, $old);
    }
    if (@bad && $croak) { croak join "\n", @bad }
    elsif (@bad)        { fatal join "\n", @bad }
}



# Horizontal justifiers

sub fillpat {
    my ($pos, $fill, $len) = @_;
    return "" if $len < 0;
    return substr($fill x max(0,($pos+$len)/length($fill)+1), $pos, $len);
}

sub jhorlit {}  # literals don't need any justification

sub jverbatim {
    jleft(@_, precropped=>1);
}

sub jleft {
    my (undef, %val) = @_;
    $_[0] =~ s/^\s+// unless $val{precropped};
    my $len = length $_[0];
    $_[0] .= fillpat($val{pos}+$len, $val{post}, $val{width}-$len);
    substr($_[0],$val{width}) = "" unless $val{stretch};
 }

 sub jright {
    my (undef, %val) = @_;
    $_[0] =~ s/\s+$// unless $val{precropped};
    $_[0] = fillpat($val{pos}, $val{pre}, $val{width}-length($_[0])) . $_[0];
    substr($_[0],0,-$val{width}) = "" unless $val{stretch};
 }

 sub jcentre {
    my (undef, %val) = @_;
    $_[0] =~ s/^\s+|\s+$//g;
    $val{precropped} = 1;
    my $indent = int( ($val{width}-length $_[0])/2 );
    jleft($_[0], %val, stretch=>0, pos=>$val{pos}+$indent, width=>$val{width}-$indent);
    jright($_[0], %val);
 }

 sub jfull {
    my ($str, %val) = @_;
    my $rem = $val{width};
    $str =~ s/^\s+|\s+$//g;
    unless ($val{last}) {
        my $rem = $val{width}-length($str);
        $str = reverse $str;
        1 while $rem>0 && $str =~ s/( +)/($rem-->0?" ":"").$1/ge;
        $_[0] = reverse $str;
    }
    &jleft;
 }

 sub jsingle {
    my (undef, %val) = @_;
    $_[0] = length $_[0] ? substr($_[0],0,1) : fillpat($val{pos}, $val{pre},1);
 }

 sub jfatal {
    die "Internal error in &form."
 }

 sub joverflow (\%\%) {
    $_[0]{overflow} = 1;
    %{$_[1]} = ();
    return \&jfatal;
 }

 sub jbullet {
    return ($_[0],1);
 }

 sub jnum {
    my ($fld,$precurr,$incurr,$postcurr,$width,$opts,$setplaces,$checkplaces)
        = @_;
    my $orig = $fld;
    $incurr ||= qr/(?!)/;

    my $comma_count  = $fld=~tr/,//;
    my $period_count = $fld=~tr/.//;
    my $apost_count  = $fld=~tr/ '//;
    my $integral = $comma_count > 1  && !($period_count || $apost_count)
                || $period_count > 1 && !($comma_count  || $apost_count)
                || $apost_count > 1  && !($comma_count  || $period_count);
    my ($whole, $point, $places) =
        $integral ? ($fld, "", "")
                  : ($fld =~ /^([]{>,.' 0]*)([.,]|\Q$incurr\E)([[}<0]*)/g);

    my $missing = $width-length($fld);
    if ($missing>0) { $fld = substr($fld,0,1) x $missing . $fld }

    $opts->{lfill} = '0' if $whole  =~ m/^0+/;
    $opts->{rfill} = '0' if $places =~ m/0+$/;
    my $comma = $whole =~ /([,.' ])/ ? $1 : '';
    my $grouping;
    if ($comma) {
        $grouping = $whole =~ /,(?:\]{2},\]{3}|>{2},>{3})\z/ ? [3,2] # Subcont
                  : $whole =~ /[,.' ](\]+|>+)\z/             ? [length($1)]
                  :                                            undef;
    }
    if (defined $setplaces) {
        $places = $setplaces;
        $whole = $width - length($point) - $setplaces;
    }
    else {
        $_ = length for $whole, $places;
    }
    fatal "Inconsistent number of decimal places in numeric field.\n",
          "Specified as $checkplaces but found $places"
                if $checkplaces && $places != $checkplaces;
    my $huh = substr( ('?'x$whole).$point.('?'x$places), 0, $width);
    my $duh = substr( ('#'x$whole).$point.('#'x$places), 0, $width);

    $places -= length($postcurr);

    get_locale_vals($point, $comma, $grouping) if $opts->{locale};

    return sub {
        my ($orig, %val) = @_;
        $_[0] = " "x$val{width} and return if $orig =~ /^\s*$/;
        $orig =~ s/,|\Q$incurr\E/./ if $point ne '.';
        my ($pre,$post) = ($precurr,$postcurr);
        if ($orig !~ /^\s*-/ || $orig == -$orig) {
            $pre  =~ s/^[(-]|[(-]$/ /g;
            $post =~ s/^[)-]|[)-]$/ /g;
        }
        my ($fail, $str);
        my ($w, $p);
        if ($integral) {
            local $SIG{__WARN__} = sub { $fail = 1 };
            $str = sprintf('%*d',$val{width},int($orig));
            ($w,$p) = ($str =~ /^\s*(.*)$/,"");          # integer
        }
        else {
            local $SIG{__WARN__} = sub { $fail = 1 };
            $str = sprintf('%*.*f',$val{width},$places,$orig);
            ($w,$p) = ($str =~ /^\s*(.*)\.(.*)$/g);      # floating point
        }
        if ($fail) {
            $_[0] = $huh;
        }
        else {
            if ($grouping) {
                my @groups = @$grouping;
                my $group = shift @groups;
                if ($group) {
                    $w =~ s/(\d)(\d{$group})\z/$1$comma$2/;
                    do {
                        $group = shift @groups if @groups;
                    } while $group && $w =~ s/(?<!,)(\d)(\d{$group})(?!\d)/$1$comma$2/;
                }
            }
            if (length($w) > $width || !$val{stretch} && ($w ? length($w) : 0)+length($pre) > $whole) {
                $_[0] = $duh;
            }
            else {
                $str = $integral ? $w : $w.q(.).$p;
                $str =~ s/(\.\d+?)(0+)$/$1/
                    unless $orig =~ /\.\d\{$places,\}[1-9]/;
                if ($integral && $str < 0) {
                    if ($pre =~ /[(]/ || $post =~ /[)]/) {
                        $str =~ s/-//;
                    }
                    else {
                        s/-/ / for $pre, $post;
                    }
                }
                $str =~ s/^(?:\Q$pre\E)?/$pre/;
                if ($val{pre} =~ /^0+$/) {
                    $str =~ s{^((\D*)(\d.*))\.}
                             {$2 . ("0"  x max(0,$whole-length $1)) . "$3."}e;
                    $val{pre} = " ";
                }
                my $postlen = length($post);
                if (!$integral) {
                    $str =~ s/^(.*)\./$1$point/;
                    my $width = $val{width}-$whole+length($1);
                    jleft($str,  %val, width=>$width, precropped=>1);
                    jright($str, %val, precropped=>1);
                }
                if ($integral) {
                    $str = substr((q{ } x max(0,$width)) . $str . $post, -$width);
                    $str =~ s/(?:[ ]{$postlen}([ ]*))$/$post$+/;
                }
                elsif ($postlen) {
                    $str =~ s/(?:[ ]{$postlen}([ ]*)|.{$postlen}())$/$post$+/;
                }
                $_[0] = $str;
            }
        }
    }
 }


# Vertical justifiers

sub jverlit {
    my ($height, $above, $below, $column) = @_;
    push @$column, ($column->[0]||"") while @$column < $height;
}

sub jmiddle {
    my ($height, $above, $below, $column) = @_;
    my $add = int(($height-@$column)/2);
    splice @$column, 0, 0, ($above)x$add;
    $add = $height-@$column;
    push @$column, ($below)x$add;
}

sub jbottom {
    my ($height, $above, $below, $column) = @_;
    my $pre = $height-@$column;
    splice @$column, 0, 0, ($above)x$pre;
}

sub jtop {
    my ($height, $above, $below, $column) = @_;
    my $post = $height-@$column;
    push @$column, ($below)x$post;
}


my $precurrpat  = qr/^(\{)    ([^]0>[<,']+?)  ([]>,'0])/x;
my $incurrpat   = qr/([]>0])  ([^]0>[<,'. ]+?) ([[<0])  /x;
my $postcurrpat = qr/([[<>0]) ([^]0>[<]+)     (\}$)     /x;

sub perl6_match {
    my ($str, $pat) = @_;
    use re 'eval';
    if (my @vals = $str =~ /$pat/) {
        unshift @vals, $&;
        bless \@vals, 'Perl6::Form::Rule::Okay';
    }
    else {
        bless [], 'Perl6::Form::Rule::Fail';
    }
}

my $litval;
sub litval {
    ($litval) = @_ if @_;
    return $litval;
}

my ($fld, $udnum);
sub fldvals {
    ($fld, $udnum) = @_ if @_;
    return ($fld, $udnum);
}

our $nestedbraces = qr/ \{ (?: (?> ((?!\{|\}).)+ ) | (??{ $nestedbraces }) )* \} /sx;

sub segment ($\@\%$\%) {
    my ($format, $args, $opts, $fldcnt, $argcache) = @_;
    my $width =
        defined $opts->{page}{width} ? $opts->{page}{width} : length($format);
    my $userdef = join("|", @{$opts->{field}{from}}) || qr/(?!)/;
    my $bullet  = join("|", map quotemeta, @{$opts->{bullet}}) || qr/(?!)/;
    use re 'eval';
    my @format;
    while ($format =~ /\G ((?>(?:\\.|(?!$userdef|$bullet|\{).)*))
                                                         (?{litval($^N)})
                          (?: ($userdef)                 (?{fldvals($^N,$^R)})
                            | ($bullet)                  (?{fldvals($^N,-1)})
                            | ($nestedbraces)            (?{fldvals($^N,undef)})
                          )
                      /gcsx) {
        push @format, litval(), fldvals();
    }
    push @format, substr ($format, pos($format)||0);
    my $args_req = int(@format/3);
    my (@formatters,@starred,@vstarred);
    for my $i (0..$args_req) {
        my ($literal,$field,$userdef) = @format[3*$i..3*$i+2];
        $literal =~ s/\\\{/{/g;
        push @formatters, { %std_literal,
                            width => length($literal),
                            src   => \$literal,
                          };
        $width -= length($literal);
        if (defined $field) {
            my %form;
            my %fldopts = %$opts;
            $fldcnt++;
            my ($setwidth, $setplaces, $checkwidth, $checkplaces);
            if (defined $userdef) {
                if ($userdef < 0) {
                    $form{isbullet} = \"$field";
                }
                else {
                    my ($from,$to) =
                        map $_->[$userdef], @{$opts->{field}}{'from','to'};
                    $field = $to->(perl6_match($field,$from),\%fldopts);
                }
            }
            my $fld = $field;
            my ($precurr, $incurr, $postcurr) = ("")x3;
            $form{width} = length $field;
            if ($form{isbullet}) {
                $form{vjust} = \&jtop;
                $form{hjust} = \&jbullet;
                $form{break} = \&break_bullet;
                $form{src}   = [];
                ($form{bullethole} = $field) =~ s/./ /gs;
            }
            else {
                $form{stretch} = !$form{isbullet} && $fld =~ s/[+]//;
                @form{qw(verbatim break hjust)}
                    = (1, \&break_verbatim, \&jverbatim)
                        if $fld =~ /["']/ && $fld !~ /[][><]/;
                        # was: if $fld =~ /["']/ && $fld !~ /[][]/;
                $form{trackpos} = $fld =~ s/(\{):|:(\})/$+/g;
                $form{vjust} = $fld =~ s/=//g ? \&jmiddle
                             : $fld =~ s/_//g ? \&jbottom
                             :                  \&jtop
                             ;

                ($checkwidth, $extras) = $fld =~ m/\(\s*(\d+[.,]?\d*)\s*\)/g;
                fatal "Too many width specifications in $field" if $extras;
                if ($checkwidth) {
                    $checkplaces = $checkwidth =~ s/[.,](\d+)// && $1;
                    for ($fld) {
                        s{([][><I|Vv"']) (\(\s*\d+[.,]?\d*\s*\))}
                         { $1 . ($1 x length $2) }xe and last;
                        s{(\(\s*\d+[.,]?\d*\s*\)) ([][><I|V"'])}
                         { ($2 x length $1) . $2 }xe and last;
                        s{(> [.,]) (\(\s*\d+[.,]?\d*\s*\))}
                         { $1 . ('<' x length $2) }xe and last;
                        s{(\(\s*\d+[.,]?\d*\s*\)) ([.,] <)}
                         { ('>' x length $1) . $2 }xe and last;
                        s{(\(\s*\d+[.,]?\d*\s*\)) ([.,] \[)}
                         { (']' x length $1) . $2 }xe and last;
                        s{(\(\s*\d+[.,]?\d*\s*\))}
                         { '[' x length $1 }xe and last;
                    }
                }

                ($setwidth, $extras) = $fld =~ m/\{\s*(\d+[.,]?\d*|\*)\s*\}/g
                                   and $fld =~ s/\{\s*(\d+[.,]?\d*|\*)\s*\}//;
                fatal "Too many width specifications in $field"
                    if $extras || $setwidth && $checkwidth;
                if ($setwidth && $setwidth =~ s/[.,](\d+)//) {
                    $setplaces = $1 || 0;
                }

                for ([$checkwidth, $checkplaces], [$setwidth, $setplaces]) {
                    fatal "Can't fit $_->[1] decimal place",($_->[1]!=1?'s':''),
                          " in a $_->[0]-character field"
                              if defined($_->[0]) && defined($_->[1])
                              && $_->[0] ne '*'
                              && $_->[0] <= $_->[1];
                }

                $precurr =
                    $fld =~ s/$precurrpat/$1.($3 x length $2).$3/e  ? "$2" : "";
                $incurr =
                    $fld =~ m/$incurrpat/                           ? "$2" : "";
                $postcurr =
                    $fld =~ s/$postcurrpat/$1.($1 x length $2).$3/e ? "$2" : "";

                if ($form{width} == 2) {
                    $fld = '[[';
                }
                elsif ($form{width} == 3) {
                    $fld =~ s/^ \{ ([.,]) \} $/].[/x;
                    $fld =~ s/^ \{ (.)    \} $/$+$+$+/x;
                }
                elsif ($form{width} > 3)  {
                    $fld =~ s/^ \{ ([]>,]+ ([]>])) \} $/$2$2$1/x;   # Integral comma'd field
                    $fld =~ s/^ \{ ([.,] \[)   /]$1/x;
                    $fld =~ s/^ \{ ([.,] \<)   />$1/x;
                    $fld =~ s/(\] .* [.,]) \} $/$1\[/x;
                    $fld =~ s/(\> .* [.,]) \} $/$1</x;
                    $fld =~ s/^ \{ (.) | (.) \} $/$+$+/gx;
                }

                $form{width} = $setwidth
                    if defined $setwidth && $setwidth ne '*';

                if ($form{width} == 2) {
                    $fld = substr($fld,0,1) x 2;
                }
                elsif ($form{width} == 3) {
                    $fld =~ s/^ \{ ([.,]) \} $/].[/x;
                    $fld =~ s/^ \{ (.)    \} $/$+$+$+/x;
                }
                elsif ($form{width} > 3)  {
                    $fld =~ s/^ \{ ([.,] \[)   /]$1/x;
                    $fld =~ s/^ \{ ([.,] \<)   />$1/x;
                    $fld =~ s/(\] .* [.,]) \} $/$1\[/x;
                    $fld =~ s/(\> .* [.,]) \} $/$1</x;
                    $fld =~ s/^ \{ (.) | (.) \} $/$+$+/gx;
                }

                $form{width} = $setwidth
                    if defined $setwidth && $setwidth ne '*';
            }

            if ($setwidth && $setwidth eq '*')  {
                push @{$form{verbatim} ? \@vstarred : \@starred}, \%form;
            }
            else {
                $width -= $form{width}
            }

            $form{line} = 1 unless $form{isbullet} || $fld =~ /[][IV"]/;

            $form{hjust} ||= $form{width} == 1                   ? \&jsingle
                           : ($fld =~ /^(?:<+|\[+)$/)            ? \&jleft
                           : ($fld =~ /^(?:>+|\]+)$/)            ? \&jright
                           : ($fld =~ /^(?:I+|\|+|>+<+|\]+\[+)$/)? \&jcentre
                           : ($fld =~ /^(?:<+>+|\[+\]+)$/)       ? \&jfull
                           : ($fld =~ /^(?:V+)$/)                ? joverflow(%form, %fldopts)
                           : ($fld =~ /^(?: [>,' 0]*  \.          [<0]*
                                          | [],' 0]*  \.          [[0]*
                                          | [>.' 0]*  \,          [<0]*
                                          | [].' 0]*  \,          [[0]*
                                          | [>.,' 0]* \Q$incurr\E [<0]*
                                          | [].,' 0]* \Q$incurr\E [[0]*
                                          | [].' 0]*  \,          [[0]*
                                        )$/x)                       ? do {
                                      $form{break}=\&break_nl;
                                      jnum($fld,$precurr,$incurr,$postcurr,
                                           $form{width},\%fldopts,
                                           $setplaces, $checkplaces)
                                                                        }
                           : fatal "Field $fldcnt is of unknown type: $field"
                           ;

            $form{break}=\&break_nl if $form{stretch};

            fatal "Inconsistent width for field $fldcnt.\n",
                  "Specified as '$field' but actual width is $form{width}"
                if defined $checkwidth && $form{width} != $checkwidth;

            splice @$args, $i, 0, "" if $form{isbullet}; # BEFORE ANY OPTIONS

            while (ref $args->[$i] eq 'HASH') {
                update %fldopts, %{splice @$args, $i, 1};
            }
            $form{opts} = \%fldopts;

            splice @$args, $i, 0, "" if $form{overflow}; # AFTER ANY OPTIONS

            fatal "Missing data value for field ", $i, " ($field)"
                unless defined $args->[$i];

            for ($args->[$i]) {
                next if $form{isbullet};
                $form{src} ||=
                    ref eq 'ARRAY' ? do {
                            my $s = join "", map { my $val = $_; $val =~ s/\n(?!\z)/\r/g; $val }
                                             map {!defined() ? "\n"
                                                 : /\n\z/    ? $_
                                                 :             "$_\n"}  @$_;
                            $form{trackpos} ? ($argcache->{$_} ||= \$s) : \$s;
                            }
                  : (readonly $_ || !$form{trackpos}) ? \(my$s=$_)
                  : \$_;
            }

            $form{break} ||= $fldopts{break} || $opts->{break};

            push @formatters, \%form;
        }
    }
    splice @$args, 0, $args_req;
    $_[-1] = $fldcnt;   # remember field count
    # Distribute {*} widths...
    for my $f (@vstarred) {
        $f->{maxwidth} = max 0, map {length} split "\n", ${$f->{src}};
    }
    if (@starred||@vstarred) {
        my $fldwidth = int($width/(@starred+@vstarred));
        for my $f (@vstarred) {
            $f->{width} = @starred ? $f->{maxwidth}
                                   : min $fldwidth, $f->{maxwidth};
            $width += $fldwidth - $f->{width};
        }
        $fldwidth = int($width/(@starred+@vstarred)) if @starred;
        $_->{width} = $fldwidth for @starred;
    }

    # Attach bullets to neighbouring fields,
    # and compute offsets from left margin...
    my $offset = 0;
    my $lastbullet;
    for my $f (@formatters) {
        $f->{pos} = $offset;
        $offset += $f->{width};
        if ($lastbullet) {
            if ($f->{literal}) {  # IGNORE IT
            }
            elsif ($f->{isbullet}) {
                my $literal = ${$lastbullet->{isbullet}};
                %$lastbullet = (%std_literal, width=>length($literal), src=>\$literal);
                $lastbullet = undef;
            }
            else {
                $f->{hasbullet} = $lastbullet;
                $lastbullet = undef;
            }
        }
        $lastbullet = $f if $f->{isbullet};
    }
    if ($lastbullet) {
        my $literal = ${$lastbullet->{isbullet}};
        %$lastbullet = (%std_literal, width=>length($literal), src=>\$literal);
    }

    return \@formatters;
}

sub layout_groups {
    my @groups;
    my $i = 0;
    FORMATTER: for my $f (@_) {
        $f->{index} = $i++;
        for my $group (@groups) {
            if ($f->{src} == $group->[0]{src}) {
                push @$group, $f;
                next FORMATTER;
            }
        }
        push @groups, [$f];
    }
    return @groups;
}

sub make_col {
    my ($f, $opts, $maxheight, $tabular) = @_;
    $maxheight = min $unlimited,
                     grep defined(), $maxheight, $f->{opts}{height}{max};
    my ($str_ref, $width) = @{$f}{qw(src width)};
    my @col;
    my ($more, $text) = (1,"");
    my $bullet = $f->{hasbullet};
    $bullet->{bullets} = [] if $bullet;
    my $bulleted = 1;
    until ($f->{done}) {
        my $skipped = 0;
        unless ($f->{isbullet} || $f->{width} == 1 || $f->{verbatim}) {
            ($skipped) = ($$str_ref =~ /\G(\s*)/gc);
            if ($skipped||=0) {
                $bulleted = ($skipped =~ /\n/);
                $skipped=~s/\r\Z//;
                $skipped = ($skipped=~tr/\r//);
                push @col, ("") x $skipped;
                last if $tabular && $bulleted && @col;
            }
        }
        my $prev_pos = pos(${$str_ref}) // -1;
        ($text,$more,$eol) = $f->{break}->($str_ref,$width,$f->{opts}{ws});
        if ($text eq q{} && $more && (pos(${$str_ref})//-1) == $prev_pos) {
            $text = substr(${$str_ref}, pos(${$str_ref}), 1);
            pos(${$str_ref})++;
            $more = pos(${$str_ref}) < length(${$str_ref});
        }
        if ($f->{opts}{ws}) {
            $text =~ s{($f->{opts}{ws})}
                      { @caps = grep { defined $$_ } 2..$#+;
                        @caps = length($1) ? " " : "" unless @caps;
                        join "", @caps;
                      }ge;
        }
        $text .= "\r" if $eol;
        push @col, $text;
        if ($bullet && $text =~ /\S/) {
            push @{$bullet->{bullets}}, ($bullet->{bullethole}) x $skipped;
            push @{$bullet->{bullets}}, $bulleted ? ${$bullet->{isbullet}}
                                                  : $bullet->{bullethole};
        }
        $f->{done} = 1
            if defined $f->{opts}{height}{max} && @col==$f->{opts}{height}{max};
        last if !$more || @col==$maxheight;
        $f->{done} = 1 if $f->{line};
        $bulleted = 0;
    }
    @col = () if @col == 1 && $col[0] eq "";
    $_[3] = $more && !$f->{done} if @_>3;
    return \@col;
}

my $count = 0;

sub balance_cols {
    my ($group, $opts, $maxheight) = @_;
    my ($first, $src) = ($group->[0], $group->[0]{src});
    if (@$group<=1) {
        $first->{formcol} = make_col($first,$opts,$maxheight);
        return;
    }
    my $pos = pos($$src) || 0;
    my $minheight = 0;
    while (1) {
        my @cols;
        pos($$src) = $pos;
        my $medheight = int(($maxheight+$minheight+1)/2);
        for my $f (@$group) {
            $f->{done} = 0;
            push @cols, make_col($f,$opts,$medheight)
        }
        if ($maxheight <= $minheight+1) {
            for (0..$#cols) {
                $group->[$_]{formcol} = $cols[$_];
            }
            return;
        }
        (substr($$src,pos$$src) =~ /\S/) ? $minheight : $maxheight = $medheight;
    }
}

sub delineate_overflows {
    for my $formats (@_) {
        # Is there a block field on the line?
        next if grep { !(  $_->{line}
                        || $_->{literal}
                        || $_->{notlastoverflow}
                        )
                     } @$formats;
        for (@$formats) {
            next unless $_->{overflow};
            if ($_->{notlastoverflow}) {
                $_->{line} = 1;
            }
        }
    }
    for my $formats (@_) {
        for (@$formats) {
            next if !$_->{overflow} || $_->{notlastoverflow};
            $_->{opts}{height}{max} = $unlimited;
            $_->{opts}{height}{minimal} = 0;
        }
    }
}

sub resolve_overflows {
    my ($formatters,$prevformatters) = @_;
    FORMATTER: for my $fld (@$formatters) {
        next unless $fld->{overflow};
        my $left  = $fld->{pos};
        my $right = $left + $fld->{width} - 1;
        my $overflowed;
        for my $prev (@$prevformatters) {
            next if $prev->{literal};
            my $prevleft  = $prev->{pos};
            my $prevright = $prevleft + $prev->{width} - 1;
            if ($right >= $prevleft && $left <= $prevright) { # overlap
                if ($overflowed) {
                    $prev->{notlastoverflow} = 1
                        if $prev->{overflow} && $prev->{src} == $fld->{src};
                    next;
                }
                my %newfld = ( %$prev, opts=>{}, overflow=>1 );
                my @keep = qw( width pos complete done line );
                @newfld{@keep} = @{$fld}{@keep};
                update %{$newfld{opts}}, %{$fld->{opts}};
                $newfld{opts}{height} = {min=>0, max=>undef, minimal=>1};
                $fld = \%newfld;
                $prev->{notlastoverflow} = 1 if $prev->{overflow};
                $overflowed = 1;
            }
        }
        croak "Useless overflow field (no field above it)"
            unless $overflowed;
    }
}

sub make_cols($$\@\%$) {
    my ($formatters,$prevformatters,$parts, $opts, $maxheight) = @_;
    my (@bullets, @max, @min);
    for my $f (@$formatters) {
        if    ($f->{isbullet})              { push @bullets, $f }
        elsif ($f->{opts}{height}{minimal}) { push @min, $f }
        else                                { push @max, $f }
    }
    my @maxgroups = layout_groups(@max);
    my @mingroups = layout_groups(@min);
    my $has_nonminimal = grep {!$_->{literal} && !$_->{line}} @max;
    if ($opts->{layout} eq 'balanced') { # balanced column-by-column
        for my $g (@maxgroups) {
            balance_cols($g,$opts, $maxheight);
        }
        $maxheight = map 0+@{$_->{formcol}||[]}, @$formatters
            if grep {!$_->{literal} && !$_->{opts}{height}{minimal}} @$formatters;
        for my $g (@mingroups) {
            balance_cols($g, $opts, $maxheight);
        }
        for my $f (@$formatters) {
            push @$parts, $f->{formcol}||$f->{bullets}||[];
        }
    }
    elsif ($opts->{layout} eq 'down') { # column-by-column
        for my $col (0..$#$formatters) {
            my $f = $formatters->[$col];
            next if $f->{isbullet} || $f->{opts}{height}{minimal};
            $parts->[$col] = make_col($f,$opts, $maxheight);
        }
        $maxheight = min $maxheight,
                         max map { defined() ? scalar @$_ : 0 } @$parts
            if $has_nonminimal;
        for my $col (0..$#$formatters) {
            my $f = $formatters->[$col];
            next if $f->{isbullet} || !$f->{opts}{height}{minimal};
            $parts->[$col] = make_col($f,$opts, $maxheight);
        }
        for my $col (0..$#$formatters) {
            my $f = $formatters->[$col];
            next unless $f->{isbullet};
            $parts->[$col] = $f->{bullets}||[];
        }
    }
    elsif ($opts->{layout} eq 'across') { # across row-by-row
        my %incomplete = (first=>1);
        for (my $row=0;$row<$maxheight && grep {$_} values %incomplete;$row++) {
            %incomplete = ();
            for my $col (0..$#$formatters) {
                $parts->[$col] ||= [];
            }
            for my $col (0..$#$formatters) {
                my $f = $formatters->[$col];
                next if $f->{isbullet} || $f->{opts}{height}{minimal};
                next if $f->{line} && $row>0 || $f->{done};
                my ($str_ref, $width) = @{$f}{qw(src width)};
                $$str_ref =~ /\G\s+/gc unless $f->{verbatim};
                ($parts->[$col][$row], my $more) =
                        $f->{break}->($str_ref,$width,$f->{opts}{ws});
                $parts->[$col][$row] =~ s/$f->{opts}{ws}/ /g if $f->{opts}{ws};
                $f->{done} = 1 if !$f->{literal}
                           && $row+1 >= ($f->{opts}{height}{max}||$maxheight);
                $incomplete{$str_ref} = $more
                    unless $f->{literal} || $f->{line} || $f->{done};
            }
            for my $col (0..$#$formatters) {
                my $f = $formatters->[$col];
                next if $f->{isbullet} || !$f->{opts}{height}{minimal};
                next if $f->{line} && $row>0 || $f->{done};
                my ($str_ref, $width) = @{$f}{qw(src width)};
                $$str_ref =~ /\G\s+/gc unless $f->{verbatim};
                ($parts->[$col][$row], my $more) =
                        $f->{break}->($str_ref,$width,$f->{opts}{ws});
                $parts->[$col][$row] =~ s/$f->{opts}{ws}/ /g if $f->{opts}{ws};
                $f->{done} = 1 if !$f->{literal}
                           && $row+1 >= ($f->{opts}{height}{max}||$maxheight);
                $incomplete{$str_ref} = $more
                    unless $has_nonminimal || $f->{done};
            }
            for my $col (0..$#$formatters) {
                my $f = $formatters->[$col];
                next unless $f->{isbullet};
                $parts->[$col][$row] = shift @{$f->{bullets}};
            }
        }
    }
    else { # tabular layout: down to the first \n, then across, then fill
        my $finished = 0;
        for my $col (0..$#$formatters) { $parts->[$col] = []; }
        while (!$finished) {
            $finished = 1;
            for my $col (0..$#$formatters) {
                my $tabular_more = 1;
                my $f = $formatters->[$col];
                next if $f->{isbullet} || $f->{opts}{height}{minimal};
                push @{$parts->[$col]},
                     @{make_col($f,$opts, $maxheight, $tabular_more)};
                $finished &&= !$tabular_more;
            }
            my $minimaxheight = min $maxheight,
                             max map { defined() ? scalar @$_ : 0 } @$parts
                if $has_nonminimal;
            for my $col (0..$#$formatters) {
                my $tabular = 1;
                my $f = $formatters->[$col];
                next if $f->{isbullet} || !$f->{opts}{height}{minimal};
                push @{$parts->[$col]},
                     @{make_col($f,$opts, $maxheight, $tabular)};
            }
            for my $col (0..$#$formatters-1) {
                my $f = $formatters->[$col];
                if ($f->{isbullet}) {
                    push @{$parts->[$col]}, @{$f->{bullets}||[]};
                    push @{$parts->[$col]},
                         ($f->{bullethole})x($minimaxheight-@{$parts->[$col]});
                }
                elsif ($f->{literal}) {
                    push @{$parts->[$col]},
                         (${$f->{src}})x($minimaxheight-@{$parts->[$col]});
                }
                else {
                    push @{$parts->[$col]},
                         ("")x($minimaxheight-@{$parts->[$col]});
                }
            }
            $maxheight -= $minimaxheight||0;
        }
    }
    for my $g (@maxgroups, @mingroups) {
        my $text = $g->[-1]{src};
        next if substr($$text,pos($$text)||0) =~ /\S/;
        for (1..@$g) {
            next unless @{$parts->[$g->[-$_]{index}]};
            $g->[-$_]{final} = 1;
            last;
        }
    }
    for my $i (1..@$parts) {
        $formatters->[-$i]{complete} = 0
    }
    for my $f (grep {!($_->{literal}||$_->{line})} @$formatters) {
        next if $f->{done} || $f->{isbullet} || $f->{opts}{height}{minimal};
        return 1 if substr(${$f->{src}},pos(${$f->{src}})||0) =~ /\S/;
    }
    return 0;
}

sub make_underline {
    my ($under, $prevline, $nextline) = @_;
    $under =~ s/(\n*)\z//;
    my $trail = "$1"|"\n";
    for my $l ($nextline, $prevline) {
        $l = join "", map {$_->{literal} ? ${$_->{src}} : '*'x$_->{width} } @$l;
        $l =~ s{(.)}{$1 =~ /\s/ ? "\0" : "\1"}ges;
    }
    $nextline |= $prevline;
    $nextline =~ s{\0}{ }g;
    $nextline =~ s{(\cA+)}{my $len=length($1); substr($under x $len,0,$len)}ge;
    $nextline .= $trail;
    return [{ %std_literal, width => length($nextline), src => \$nextline }];
}

sub linecount($) {
    return tr/\n// + (/[^\n]\z/?1:0) for @_;
}

use warnings::register;

sub form is export(:MANDATORY) {
    croak "Useless call to &form in void context" unless defined wantarray;

    # Handle formatting calls...
    my ($package, $file, $line) = caller;
    my $caller_opts = $caller_opts{$package,$file} ||= {};
    if (keys %$caller_opts) {
        $line = first { $_ < $line } sort {$b<=>$a} keys %$caller_opts;
        $caller_opts = $caller_opts->{$line} || {}
                if defined $line;
    }
    my %opts = (%def_opts, %$caller_opts);
    my $fldcnt = 0;
    my @section = {opts=>{%opts}, text=>[]};
    my $formats = \@_;
    my $first = 1;
    my %argcache;
    my ($prevformat,$currformat,@allformats);
    while (@$formats) {
        my $format = shift @$formats;
        if (ref $format eq 'HASH') {
            update %opts, %$format;
            $opts{page}{number} = undef unless defined $format->{page}{number};
            push @section, {opts=>{%opts}};
            redo;
        }
        if ($first) {   # Change format lists if data first or last
            if ($opts{interleave}) {
                $formats = [$format =~ /.*(?:\n|\z)/g];
                $format = shift @$formats;
            }
            $first = 0;
        }
        $format =~ s/\n?\z/\n/;
        $prevformat = $currformat;
        $currformat = segment($format, @_, %opts, $fldcnt, %argcache);
        resolve_overflows($currformat, $prevformat);
        if (defined $opts{under}) {
            push @{$section[-1]{formatters}},
                make_underline($opts{under}, $prevformat, $currformat);
            $opts{under} = undef;
        }
        push @{$section[-1]{formatters}}, $currformat;
        push @allformats, $currformat;
    }
    croak scalar(@_), " too many data values after last format" if @_;
    delineate_overflows(@allformats);

    my $text = "";
    my $pagetype = 'first';
    my $pagenum = 1;
    for my $section (@section) {
        next unless $section->{formatters};
        my $sect_opts = $section->{opts};
        my $page = $sect_opts->{page};
        $page->{number} = $pagenum unless defined $page->{number};
        my $pagelen = $page->{length};
        while (1) {
            my $parity = $page->{number}%2 ? 'odd' : 'even';
            my $header =
             $page->{header}{$pagetype} ? $page->{header}{$pagetype}($sect_opts)
             : $page->{header}{$parity} ? $page->{header}{$parity}($sect_opts)
             : $page->{header}{other}   ? $page->{header}{other}($sect_opts)
             : "";
            my $footer =
             $page->{footer}{$pagetype} ? $page->{footer}{$pagetype}($sect_opts)
             : $page->{footer}{$parity} ? $page->{footer}{$parity}($sect_opts)
             : $page->{footer}{other}   ? $page->{footer}{other}($sect_opts)
             : "";
            my $feed =
             $page->{feed}{$pagetype} ? $page->{feed}{$pagetype}($sect_opts)
             : $page->{feed}{$parity} ? $page->{feed}{$parity}($sect_opts)
             : $page->{feed}{other}   ? $page->{feed}{other}($sect_opts)
             : "";
            length and s/\n?\z/\n/ for $header, $footer;  # NOT for $feed
            my $bodyfn = $page->{body}{$pagetype}
                      || $page->{body}{$parity}
                      || $page->{body}{other}
                      || \&std_body;
            my $bodylen = max 1, $pagelen - linecount($header) - linecount($footer);
            my ($pagetext, $more) = make_page($section, $sect_opts, $bodylen);
            if (!$more && $section == $section[-1]) {
                my $lastheader =
                    $page->{header}{last} ? $page->{header}{last}($sect_opts)
                                          : $header;
                my $lastfooter =
                    $page->{footer}{last} ? $page->{footer}{last}($sect_opts)
                                          : $footer;
                length and s/\n?\z/\n/ for $lastheader, $lastfooter;
                my $lastlen = max 1, $pagelen-linecount($lastheader)-linecount($lastfooter);
                if (@$pagetext <= $lastlen) {
                    $pagetype = 'last';
                    ($header, $footer, $bodylen)
                        = ($lastheader, $lastfooter, $lastlen);
                    $feed = $page->{feed}{last}($sect_opts)
                        if $page->{feed}{last};
                    $bodyfn = $page->{body}{last}
                        if $page->{body}{last};
                }
            }
            my $fill = $pagelen < $unlimited ? [("\n") x max(0,$bodylen-@$pagetext)]
                                             : [];

            my $body = $bodyfn->($pagetext, $fill, \%opts);

            $text .= $header . $body . $footer . $feed;
            $page->{number}++;

            # Handle special case of empty last page...
            last unless $more || $section == $section[-1] && $pagetype ne 'last';
            $pagetype = $page->{number}%2 ? 'odd' : 'even';
        }
        $pagenum = $page->{number};
    }

    $text =~ s/[^\S\n]+\n/\n/g unless $opts{untrimmed};
    return $text;
}

sub make_page {
        my ($section, $sect_opts, $bodylen) = @_;
        my (@text, $more);
        my ($prevformatters, $formatters);
        while (@text < $bodylen && @{$section->{formatters}}) {
            $prevformatters = $formatters;
            $formatters = $section->{formatters}[0];
            $more = make_cols($formatters,$prevformatters,my @parts, %$sect_opts, $bodylen-@text);
            shift @{$section->{formatters}} unless $more;
            my $maxheight = 0;
            my $maxwidth = 0;
            for my $col (0..$#parts) {
                local $_ = $parts[$col];
                pop @$_ while @$_ && ! length($_->[-1]);
                $maxheight = max($maxheight, scalar(@$_), $formatters->[$col]{opts}{height}{min}||0);
                # $formatters->[$col]{pos} = $maxwidth;
                # $maxwidth += $formatters->[$col]{width};
            }
            for my $col (0..$#parts) {
                my $f = $formatters->[$col];
                push @{$parts[$col]}, ("") x max(0,($f->{height}{min}||0)-@{$parts[$col]});
                my $fopts = $f->{opts};
                my $tfill = first {defined $_} @{$fopts}{qw(tfill vfill fill)}, " ";
                my $bfill = first {defined $_} @{$fopts}{qw(bfill vfill fill)}, " ";
                my $lfill = first {defined $_} @{$fopts}{qw(lfill hfill fill)}, " ";
                my $rfill = first {defined $_} @{$fopts}{qw(rfill hfill fill)}, " ";
                $f->{vjust}->($maxheight,$tfill,$bfill,$parts[$col]);
                for my $row (0..$#{$parts[$col]}) {
                    my $last = $parts[$col][$row] =~ s/\r//;
                    $f->{hjust}->($parts[$col][$row], pre=>$lfill, post=>$rfill,
                                  last=>$last, pos=>$f->{pos},
                                  stretch=>$f->{stretch}, width=>$f->{width},
                                 );
                }
            }
            for my $row (0..$maxheight) {
                push @text, join "",
                    grep { defined } map $parts[$_][$row],0..$#parts;
            }
        }
        return (\@text, $more);
}

# Extract perpendicular cross-sections from an AoA, AoH, HoA, HoH, AoHoA, etc.

sub section {
    my ($structure, @index) = @_;
    $structure = [ values %$structure ] if ref $structure eq 'HASH';
    my @section;
    for my $row ( @$structure ) {
        local $,=",";
        my $type = ref $row or croak "Too many indices (starting with [@index])";
        if ($type eq 'HASH') {
            @index = keys %$row unless @index;
            push @{$section[$_]}, $row->{$index[$_]} for 0..$#index;
        }
        elsif ($type eq 'ARRAY') {
            @index = (0..$#$row) unless @index;
            push @{$section[$_]}, $row->[$index[$_]] for 0..$#index;
        }
        else {
            my $what = ref $structure;
            croak "Can't drill ", ($what ? lc $what : $structure) , " of $type";
        }
    }
    return @section;
}

sub slice {
    my ($structure, @indices) = @_;
    return ref eq 'HASH' ? @{$_}{@indices} : @{$_}[@indices] for $structure;
}

sub vals { return ref eq 'HASH' ? values %$_ : @$_ for $_[0] }

sub drill (\[@%];@) is export {
    my ($structure, @indices) = @_;
    return $structure unless @indices;
    my $index = shift @indices;
    my @section = [ @$index ? slice($structure,@$index) : vals($structure) ];
    return @section unless @indices;
    for my $index (@indices) {
        @section = map {section $_, @$index} @section;
    }
    return @section;
}

sub break_lit {
    return (${$_[0]},0,0);
}

sub break_bullet {
    my ($src) = @_;
    my $next = pop @$src || "";
    return ($next,@$src>0,0);
}

sub break_verbatim {
    my ($str,$rem) = @_;
    $$str =~ m/ \G ([^\n\r]*) (?:\r|\n|\z) /gcx or return ("",0);
    return (substr("$1",0,$rem), $$str =~ m/ \G (?=.) /sgcx ? 1 : 0,0);
}

sub break_nl {
    my ($str) = @_;
    if ($$str =~ m/\G [^\S\n\r]* ([^\n\r]*?) [^\S\r\n]* (?:\r|$)/gcxm)  {
        return ("$1", $$str =~ /\G(?=.*\S)/sgc?1:0, 1);
    }
    else {
        return ("",0,0);
    }
}

my $wsnzw = q{ (??{length($^N)?'(?=)':'(?!)'}) };

sub break_at is export {
    my ($hyphen) = @_;
    my ($lit_hy) = qr/\Q$hyphen\E/;
    my $hylen = length($hyphen);
    my @ret;
    return sub {
        my ($str,$rem,$ws) = @_;
        my ($last_breakable, $res) = ($rem+1,"", 0);
        for ($$str) {
            use re 'eval';
            while ($rem > 0 && (pos()||0) < length()) {
                if ($ws && /\G ($ws) $wsnzw/gcx) {
                    my $captured;
                    if ($#+ > 1) {      # may be extra captures...
                        for (2..$#+) {
                            next unless defined $$_;
                            $captured++;
                            $res .= $$_;
                            $rem -= length $$_;
                        }
                    }
                    unless ($captured) {
                        $res .= $1;
                        $rem--;
                    }
                    $last_breakable = length $res;
                }
                elsif ($rem>=$hylen && /\G $lit_hy /gcx) {
                    $res .= $hyphen;
                    $rem -= $hylen;
                    $last_breakable = length $res;
                }
                elsif (/\G ((?!$lit_hy)[^\n\r]) /gcx) {
                    $res .= $1;
                    $rem--;
                    $last_breakable = length $res if $res =~ /\s$/;
                }
                else { last }
            }
            my $reslen = length $res;
            $ws ||= qr/\s/;
            unless (/\G (?=$lit_hy|($ws)$wsnzw|\z|\n|\r) /gcx) {
                if ($last_breakable <= $reslen) {
                    pos() -= $reslen-$last_breakable;
                    substr($res,$last_breakable) = "";
                }
                elsif ($reslen > $hylen) {
                    if ($res =~ /\S\S\S{$hylen}$/) {
                        pos() -= $hylen;
                        substr($res,-$hylen) = $hyphen;
                    }
                    elsif ($res =~ s/(\S+)$//) {
                        pos() -= length($1);
                    }
                }
            }
            my $rem = substr($$str, pos $$str);
            return ($res, $rem=~/\S/?1:0, $rem =~ /^\s*(?:\z|\n|\r)/);
        }
    };
}

sub import {
    my $class = shift;
    my ($package, $file, $line) = caller;
    my %opts;
    for (@_) {
        croak "Options for $class must be specified in a hash"
            unless ref eq 'HASH';
        update(%opts, %$_, 'croak');
    }
    $caller_opts{$package,$file}{$line} = \%opts;
}

package Perl6::Form::Rule::Fail;
use overload
    '""'   => sub{ undef },
    '0+'   => sub{ undef },
    'bool' => sub{ 0 },
;

package Perl6::Form::Rule::Okay;
use overload
    '""'   => sub{ $_[0][0] },
    '0+'   => sub{ $_[0][0] },
    'bool' => sub{ 1 },
;

1;
__END__

=head1 NAME

Perl6::Form - Implements the Perl 6 'form' built-in


=head1 SYNOPSIS

    use Perl6::Form;

    $text = form ' =================================== ',
                 '| NAME     |    AGE     | ID NUMBER |',
                 '|----------+------------+-----------|',
                 '| {<<<<<<} | {||||||||} | {>>>>>>>} |',
                    $name,     $age,        $ID,
                 '|===================================|',
                 '| COMMENTS                          |',
                 '|-----------------------------------|',
                 '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
                    $comments,
                 ' =================================== ';


=head1 DESCRIPTION

Formats are Perl 5's mechanism for creating text templates with
fixed-width fields. Those fields are then filled in using values from
prespecified package variables.

Unlike Perl 5, Perl 6 doesn't have a C<format> keyword. Or the
associated built-in formatting mechanism. Instead it has a Form.pm
module. And a C<form> function.

Like a Perl 5 C<format> statement, the C<form> function takes a series
of format (or "picture") strings, each of which is immediately
followed by a suitable set of replacement values. It interpolates
those values into the placeholders specified within each picture string,
and returns the result:

    $text = form
                 $format_f1,
                     $datum1, $datum2, $datum3,
                 $format_f2,
                     $datum4,
                 $format_f3,
                     $datum5;

So, whereas in Perl 5 we might write:

    # Perl 5 code...

    our ($name, $age, $ID, $comments);

    format STDOUT
     ===================================
    | NAME     |    AGE     | ID NUMBER |
    |----------+------------+-----------|
    | @<<<<<<< | @||||||||| | @>>>>>>>> |
      $name,     $age,        $ID,
    |===================================|
    | COMMENTS                          |
    |-----------------------------------|
    | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |~~
      $comments,
     ===================================
    .

    write STDOUT;


in Perl 6 we could write:

    # Perl 6 code...

    print form
        ' =================================== ',
        '| NAME     |    AGE     | ID NUMBER |',
        '|----------+------------+-----------|',
        '| {<<<<<<} | {||||||||} | {>>>>>>>} |',
           $name,     $age,        $ID,
        '|===================================|',
        '| COMMENTS                          |',
        '|-----------------------------------|',
        '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
           $comments,
        ' =================================== ';

And both of them would print something like:

     ===================================
    | NAME     |    AGE     | ID NUMBER |
    |----------+------------+-----------|
    | Richard  |     33     |    000003 |
    |===================================|
    | COMMENTS                          |
    |-----------------------------------|
    | Talks to self. Seems to be        |
    | overcompensating for inferiority  |
    | complex rooted in post-natal      |
    | maternal rejection due to         |
    | handicap (congenital or perhaps   |
    | the result of premature birth).   |
    | Shows numerous indications of     |
    | psychotic (esp. nepocidal)        |
    | tendencies. Naturally, subject    |
    | gravitated to career in politics. |
     ===================================


This module implements virtually all of the functionality
of the Perl 6 Form.pm module. The only differences are:

=over

=item *

Option pairs must be passed in a hash reference;

=item *

Array data sources must be passed as array references;

=item *

Options specified on the C<use Perl6::Form> line are
not (yet) lexically scoped;

=item *

User-defined line-breaking subroutines are passed their data source as a
reference to a scalar;

=back

=head2 Formatting jargon

=over

=item Format

A string that is used as a template for the creation of I<text>. It will
contain zero or more I<fields>, usually with some literal characters and
whitespace between them.

=item Text

A string that is created by replacing the fields of a format with specific
I<data> values.  For example, the string that a call to C<form> returns.

=item Field

A fixed-width slot within a format string, into which I<data> will be formatted.

=item Data

A string or numeric value (or an array of such values) that is
interpolated into a format, in order to fill in a particular field.

=item Single-line field

A field that interpolates only as much of its corresponding data value as
will fit inside it within a single line of text.

=item Block field

A field that interpolates all of its corresponding data value, over a
series of text lines E<ndash> as many as necessary E<ndash> producing a
I<text block>.

=item Text block

The column of newline-separated text lines. A text block is produced
when data is formatted into a block field that is too small to contain
the data in a single line

=item Column

The amount of space on an output device required to display one single-width
character. One character will occupy one column in most cases, the most
obvious exceptions being CJK double-width characters.

=back

=head2 Return values

When called in a scalar or list context, C<form> returns a string
containing the complete formatted text:

    my $formatted_text = form $format, *@data;

    @texts = ( form($format, *@data1), form($format, *@data2) );  # 2 elems

When called in a void context, C<form> dies, bitterly
pointing out how useless that is to format something and then just
throw the result away.


=head1 Field types

The format strings passed to C<form> determine what the resulting
formatted text looks like. Each format consists of a series
of field specifiers, which are usually separated by literal characters.

C<form> understands a far larger number of field specifiers than C<format> did,
designed around a small number of conventions:

=over

=item *

Each field is enclosed in a pair of braces.

=item *

Within the braces, left or right angle brackets (C<< < >> or C<< > >>), bars
(C<|>), and single-quotes (C<'>) indicate various types of single-line fields.

=item *

Left or right square brackets (C<[> or C<]>), I's (C<I>), and double-
quotes (C<">) indicate block fields of various types.

=item *

The direction of the brackets within a field indicates the direction
towards which text will be justified in that field. For example:

    {<<<<<<<<<<<}   Justify the text to the left
    {>>>>>>>>>>>}                  Justify the text to the right
    {>>>>>><<<<<}                 Centre the text
    {<<<<<<>>>>>}   Fully  justify  the  text  to  both  margins

This is even true for numeric fields, which look like:
C<<<<<<< {>>>>>.<<} >>>>>>>. The whole digits are right-justified before
the dot and the decimals are left-justified after it.

=item *

An C<=> at either end of a field (or both ends) indicates the data
interpolated into the field is to be vertically "middled" within the
resulting block. That is, the text is to be centred vertically on the
middle of all the lines produced by the complete format.

=item *

An C<_> at the start and/or end of a field indicates the interpolated data
is to be vertically "bottomed" within the resulting block. That is, the
text is to be pushed to the bottom of the lines produced by the format.

=back

For example:

                                      Field specifier
    Field type                 One-line             Block
    ==========                ==========          ==========

    left justified            {<<<<<<<<}          {[[[[[[[[}
    right justified           {>>>>>>>>}          {]]]]]]]]}
    centred                   {>>>><<<<}          {]]]][[[[}
    centred (alternative)     {||||||||}          {IIIIIIII}
    fully justified           {<<<<>>>>}          {[[[[]]]]}
    verbatim                  {''''''''}          {""""""""}

    numeric                   {>>>>>.<<}          {]]]]].[[}
    euronumeric               {>>>>>,<<}          {]]]]],[[}
    comma'd                   {>,>>>,>>>.<<}      {],]]],]]].[[}
    space'd                   {> >>> >>>.<<}      {] ]]] ]]].[[}
    eurocomma'd               {>.>>>.>>>,<<}      {].]]].]]],[[}
    Swiss Army comma'd        {>'>>>'>>>,<<}      {]']]]']]],[[}
    subcontinental            {>>,>>,>>>.<<}      {]],]],]]].[[}

    signed numeric            {->>>.<<<}          {-]]].[[[}
    post-signed numeric       {>>>>.<<-}          {]]]].[[-}
    paren-signed numeric      {(>>>.<<)}          {(]]].[[)}

    prefix currency           {$>>>.<<<}          {$]]].[[[}
    postfix currency          {>>>.<<<DM}         {]]].[[[DM}
    infix currency            {>>>$<< Esc}        {]]]$[[ Esc}

    left/middled              {=<<<<<<=}          {=[[[[[[=}
    right/middled             {=>>>>>>=}          {=]]]]]]=}
    infix currency/middled    {=>>$<< Esc}        {=]]$[[ Esc}
    eurocomma'd/middled       {>.>>>.>>>,<<=}     {].]]].]]],[[=}
    etc.

    left/bottomed             {_<<<<<<_}          {_[[[[[[_}
    right/bottomed            {_>>>>>>_}          {_]]]]]]_}
    etc.


=head1 How fields are filled

When data is interpolated into a line field, the field grabs as much of the
data as will fit on a single line, formats that data appropriately, and
interpolates it into the format.

That means that if we use a one-line field, it only shows as much of the data
as will fit on one lime. For example:

    my $data1 = 'By the pricking of my thumbs, something wicked this way comes';
    my $data2 = 'A horse! A horse! My kingdom for a horse!';

    print form
        '...{<<<<<<<<<<<<<<<<<}...{>>>>>>>}...',
            $data1,               $data2;

prints:

    ...By the pricking of ... A horse!...

On the other hand, if our format string used block fields instead, the
fields would extract one line of data at a time, repeating that process as
many times as necessary to display all the available data. So:

    print form
        '...{[[[[[[[[[[[[[[[[[}...{]]]]]]]}...',
            $data1,               $data2;

would produce:

    ...By the pricking of ... A horse!...
    ...my thumbs,         ... A horse!...
    ...something wicked   ...       My...
    ...this way comes     ...  kingdom...
    ...                   ...    for a...
    ...                   ...   horse!...


We can mix line fields and block fields in the same format and C<form> will
extract and interpolate only as much data as each field requires. For example:

    print form
        '...{<<<<<<<<<<<<<<<<<}...{]]]]]]]}...',
            $data1,               $data2;

which produces:

    ...By the pricking of ... A horse!...
    ...                   ... A horse!...
    ...                   ...       My...
    ...                   ...  kingdom...
    ...                   ...    for a...
    ...                   ...   horse!...

Notice that, after the first line, the single-line
C<<<<<<< {<<<<<<} >>>>>>> field is simply replaced by
the appropriate number of space
characters, to keep the columns correctly aligned.

The usual reason for mixing line and block fields in this way is to
allow numbered or bulleted points:

    print "I couldn't do my English Lit homework because...\n\n";

    my $index = 0;
    for my $reason (@reasons) {
        my $n = @reasons - $index . '.';
        print form '   {>}  {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
                       $n,  $reason,
                   '';
    }

which might produce:

    I couldn't do my English Lit homework because...

         10. Three witches told me I was going to be
             king.

          9. I was busy explaining wherefore am I Romeo.

          8. I was busy scrubbing the blood off my
             hands.

          7. Some dear friends had to charge once more
             unto the breach.

          6. My so-called best friend tricked me into
             killing my wife.

          5. My so-called best friend tricked me into
             killing Caesar.

          4. My so-called best friend tricked me into
             taming a shrew.

          3. My uncle killed my father and married my
             mother.

          2. I fell in love with my manservant, who was
             actually the disguised twin sister of the
             man that my former love secretly married,
             having mistaken him for my manservant who
             was wooing her on my behalf whilst secretly
             in love with me.

          1. I was abducted by fairies.


=head1 Keeping track of what's been formatted

Obviously, as a call to C<form> builds up each line of its output
E<ndash> extracting data from one or more data arguments and
formatting it into the corresponding fields E<ndash> it needs to keep
track of where it's up to in each datum. It does this by progressively
updating the C<pos> of each datum, in exactly the same way as a
pattern match does.

And as with a pattern match, by default that updated C<pos> is only
used internally and B<not> preserved after the call to C<form> is
finished. So passing a string to C<form> doesn't interfere with any
other pattern matching or text formatting that we might
subsequently do with that data.

However, sometimes we I<do> want to know how much of our data a call to C<form>
managed to extract and format. Or we may want to split a formatting task
into several stages, with separate calls to C<form> for each stage.
So we need a way of telling C<form> to preserve the C<pos> information
in our data.

But, if we want to apply a series of C<form> calls to the same data we also
need to be able to tell C<form> to I<respect> the C<pos> information
of that data E<ndash> to start extracting from the previously preserved
C<.pos> position, rather than from the start of the string.

To achieve both those goals, we use a I<follow-on field>. That is we use
an ordinary field but mark it as C<pos>-sensitive with a special
notation: ASCII colons at either end. So instead of
C<<<<< {<<<<>>>>} >>>>>, we'd write C<<<<< {:<<<>>>:} >>>>>.

Follow-on fields are most useful when we want to split a formatting task
into distinct stages E<ndash> or iterations E<ndash> but still allow the
contents of the follow-on field to flow uninterrupted from line to line.
For example:

    print "The best Shakespearean roles are:\n\n";

    for my $role (@roles) {
        print form "   * {<<<<<<<<<<<<<<<<<<<<<<<<<<<<}   *{:<<<<<<<>>>>>>>:}*",
                         $role,                            $disclaimer;
    }

which produces:

    The best Shakespearean roles are:

       * Macbeth                          *WARNING:          *
       * King Lear                        *This list of roles*
       * Juliet                           *constitutes      a*
       * Othello                          *personal   opinion*
       * Hippolyta                        *only and is in  no*
       * Don John                         *way  endorsed   by*
       * Katerina                         *Shakespeare'R'Us. *
       * Richard                          *It   may   contain*
       * Malvolio                         *nuts.             *
       * Bottom                           *                  *

The multiple calls to C<form> manage to produce a coherent disclaimer
because the colons in the second field tell each call to start
extracting data from C<$disclaimer> at the offset indicated by
C<pos $disclaimer>, and then to update C<pos $disclaimer> with
the final position at which the field extracted data. So the next time
C<form> is called, the follow-on field starts extracting from
where it left off in the previous call.

Follow-on fields are similar to C<<<<<< ^<<<<< >>>>>> fields in a Perl 5 format,
except they don't destroy the contents of a data source; they merely change that
data source's C<pos> marker.


=head1 Array data sources

Data, especially numeric data, is often stored in arrays.
So C<form> also accepts arrays as data arguments too. Or, more precisely, it
accepts B<references> to arrays as arguments.

Once inside C<form>, each array that was specified as the data source
for a field is internally converted to a single string by joining it
together with a newline between each element.

The upshot is that, instead of:

    print "The best Shakespearean roles are:\n\n";

    for my $role (@roles) {
        print form "   * {<<<<<<<<<<<<<<<<<<<<<<<<<<<<}   *{:<<<<<<<>>>>>>>:}*",
                         $role,                            $disclaimer;
    }

we could just write:

    print "The best Shakespearean roles are:\n\n";

    print form "   * {[[[[[[[[[[[[[[[[[[[[[[[[[[[[}   *{[[[[[[[[]]]]]]]]}*",
                     \@roles,                          $disclaimer;

And the array of roles would be internally converted to a single string, with
one role per line. Note that we also changed the disclaimer field to a regular
block field, so that the entire disclaimer would be formatted. And there was
no longer any need for the disclaimer field to be a follow-on field, since the
block field would extract and format the entire disclaimer anyway.


Array data sources are particularly
useful when formatting, especially if the data is known to fit within
the specified width. For example:

    print form
        '-------------------------------------------',
        'Name             Score   Time  | Normalized',
        '-------------------------------------------',
        '{[[[[[[[[[[[[}   {III}   {II}  |  {]]].[[} ',
         \@name,          \@score,\@time,  [map {$score[$_]/$time[$_]} 0..$#score]

is a very easy way to produce the table:

    -------------------------------------------
    Name             Score   Time  | Normalized
    -------------------------------------------
    Thomas Mowbray    88      15   |     5.867
    Richard Scroop    54      13   |     4.154
    Harry Percy       99      18   |     5.5


=head2 Justifying fields

The most commonly used fields are those that justify their contents: to
the left, to the right, to the left I<and> right, or towards the centre.

Left-justified and right-justified fields extract from their data source
the largest substring that will fit inside them, push that string to the
left or right as appropriate, and then pad the string out to the
required field width with spaces (or the L<nominated fill character|
"He doth fill fields with harness...">).

Centred fields (C<<<<< {>>>><<<<} >>>>> and C<{]]]][[[[}>) likewise
extract as much data as possible, and then pad both sides of it with
(near) equal numbers of spaces. If the amount of padding required is not
evenly divisible by 2, the one extra space is added I<after> the data.

There is a second syntax for centred fields E<ndash> a tip-o'-the-hat to
Perl 5 formats: C<{|||||||||}> and C<{IIIIIIII}>. This variant also
makes it easier to specify centering fields that are only three columns
wide: C<{|}> and C<{I}>.

Note, however, that the behaviour of centering fields specified this
way is exactly the same in every respect as the bracket-based versions, so
we're free to use whichever we prefer.

Fully justified fields (C<<<<< {<<<<>>>>} >>>>> and C<{[[[[]]]]}>)
extract a maximal substring and then distribute any padding as evenly as
possible into the existing whitespace gaps in that data. For example:

    print form '({<<<<<<<<<>>>>>>>>>>>})',
               'A fellow of infinite jest, of most excellent fancy';

would print:

    (A fellow  of  infinite)

A fully-justified block field (C<{[[[[]]]]}>) does the same across
multiple lines, except that the very last line is always left-justified.
Hence, this:

    print form '({[[[[[[[[]]]]]]]})',
               'All the world's a stage, And all the men and women merely players.'

would print:

    (All the world's a)
    (stage,  And   all)
    (the men and women)
    (merely players.  )

By the way, with both centred fields (C<<<<< {>>>><<<} >>>>>) and fully
justified fields (C<<<<< {<<<>>>>} >>>>>), the actual number of
left vs right arrows is irrelevant, so long as there is at least
one of each.


=head1 Short fields

One special case we need to consider is an empty set of field delimiters:

    form 'ID number: {}'

This specification is treated as a two-column-wide, left-justified
block field (since that seems to be the type of two-column-wide
field most often required).

Other kinds of two-column (and single-column) fields can also
be created using L<imperative field widths|"Imperative fields widths"> and
and L<user-defined fields|"User-defined fields">.


=head1 Numerical fields

A field specifier of the form C<<<<< {>>>>.<<} >>>>> or C<{]]]].[[}>
represents a decimal-aligned numeric field. The decimal marker always
appears in exactly the position indicated and the rest of the number is
aligned around it. The decimal places are rounded to the specific number
of places indicated, but only "significant" digits are shown. For example:

    @nums = (1, 1.2, 1.23, 11.234, 111.235, 1.0001);

    print form "Thy score be: {]]]].[[}",
                              \@nums;

prints:

    Thy score be:     1.0
    Thy score be:     1.2
    Thy score be:     1.23
    Thy score be:    11.234
    Thy score be:   111.235
    Thy score be:     1.000


=head2 Non-numeric data

You're probably wondering what happens if we try to format a number that's too
large for the available places (as C<123456.78> would be in the above format).
Whereas C<sprintf> would extend a numeric field to accommodate the number,
C<form> insists on preserving the specified layout; in particular, the
position of the decimal point. But it obviously can't just cut off the
extra high-order digits; that would change the value:

    Thy score be: 23456.78

So, instead, it indicates that the number doesn't fit by filling the
field with octothorpes (the way many spreadsheets do):

    Thy score be: #####.###

It's also possible that someone (not you, of course!) might attempt to
pass a numeric field some data that isn't numeric at all:

    my @mixed_data = (1, 2, "three", {4=>5}, "6", "7-Up");

    print form 'Thy score be: {]]]].[[}',
                              \@mixed_data;


Unlike Perl itself, C<form> doesn't autoconvert non-numeric values.
Instead it marks them with another special string, by filling the field with
question-marks:

    Thy score be:     1.0
    Thy score be:     2.0
    Thy score be: ?????.???
    Thy score be: ?????.???
    Thy score be:     6.0
    Thy score be: ?????.???

Note that strings per se aren't a problem E<ndash> C<form> will happily
convert strings that contain valid numbers, such as C<"6"> in the above
example. But it does reject strings that contain anything else besides
a number (even when Perl itself would successfully convert the number
E<ndash> as it would for C<"7-Up"> above).

Those who'd prefer Perl's usual, more laissez-faire attitude to
numerical conversion can just pre-numerify the values
themselves:

    print form 'Thy score be: {]]]].[[}',
                              [map {$_+0} @mixed_data];

This version would print something like:

    Thy score be:     1.0
    Thy score be:     2.0
    Thy score be:     0.0
    Thy score be:     1.0
    Thy score be:     6.0
    Thy score be:     7.0


=head2 Decimal markers

Of course, not everyone uses a dot for their decimal point. The other main
contender is the comma, and naturally C<form> supports that as well. If
we specify a numeric field with a comma between the brackets:

    @les_nums = (1, 1.2, 1.23, 11.234, 111.235, 1.0001);

    print form 'Votre score est: {]]]],[[}',
                                 \@les_nums;

the call prints:

    Votre score est:     1,0
    Votre score est:     1,2
    Votre score est:     1,23
    Votre score est:    11,234
    Votre score est:   111,235
    Votre score est:     1,000

In fact, C<form> is extremely flexible about the characters
we're allowed to use as
a decimal marker: anything except an angle- or square bracket or
a plus sign is acceptable.

As a bonus, C<form> allows us to use the specified decimal marker in
the I<data> as well as in the format. So this works too:

    @les_nums = ("1", "1,2", "1,23", "11,234", "111,235", "1,0001");

    print form 'Vos score est: {]]]],[[}',
                               \@les_nums;


=head2 Negative numbers

Negative numbers work as expected, with the minus sign taking
up one column of the field's allotted span:

    @nums = ( 1, -1.2,  1.23, -11.234,  111.235, -12345.67);

    print form 'Thy score be: {]]]].[[}',
                              \@nums;

This would print:

    Thy score be:     1.0
    Thy score be:    -1.2
    Thy score be:     1.23
    Thy score be:   -11.234
    Thy score be:   111.235
    Thy score be: #####.###

However, C<form> can also format numbers so that the minus sign I<trails> the
number. To do that we simple put an explicit minus sign inside the field
specification, at the end:

    print form 'Thy score be: {]]]].[[-}',
                              \@nums;

which would then print:

    Thy score be:     1.0
    Thy score be:     1.2-
    Thy score be:     1.23
    Thy score be:    11.234-
    Thy score be:   111.235
    Thy score be: 12345.67-

C<form> also understands the common financial usage where negative
numbers are represented as positive numbers in parentheses. Once again,
we draw an abstract picture of what we want (by putting parens at either
end of the field specification):

    print form 'Thy dividend be: {(]]]].[[)}',
                                 \@nums;

and C<form> obliges:

    Thy dividend be:      1.0
    Thy dividend be:     (1.2)
    Thy dividend be:      1.23
    Thy dividend be:    (11.234)
    Thy dividend be:    111.235
    Thy dividend be: (12345.67)

Note that the parens have to go I<inside> the field's braces. Otherwise,
they're just literal parts of the format string.

=head2 Thousands separators

If we add so-called "thousands separators" inside a numeric field at the
usual places, C<form> includes them appropriately in its output. It can
handle the five major formatting conventions:

    my @nums = (0, 1, 1.1, 1.23, 4567.89, 34567.89, 234567.89, 1234567.89);

    print form
        'Brittannic      Continental     Subcontinental   Tyrolean        Asiatic',
        '_____________   _____________   ______________   _____________   _____________',
        '{],]]],]]].[}   {].]]].]]],[}    {]],]],]]].[}   {]']]]']]],[}   {]]]],]]]].[}',
         \@nums,         \@nums,          \@nums,         \@nums,         \@nums;

to produce:

    Brittannic      Continental     Subcontinental   Tyrolean        Asiatic
    _____________   _____________   ______________   _____________   _____________
             0.0             0,0              0.0             0,0             0.0
             1.0             1,0              1.0             1,0             1.0
             1.1             1,1              1.1             1,1             1.1
             1.23            1,23             1.23            1,23            1.23
         4,567.89        4.567,89         4,567.89        4'567,89         4567.89
        34,567.89       34.567,89        34,567.89       34'567,89       3,4567.89
       234,567.89      234.567,89      2,34,567.89      234'567,89      23,4567.89
     1,234,567.89    1.234.567,89     12,34,567.89    1'234'567,89     123,4567.89

It also accepts a space character as a "thousands separator" (with, of
course, any decimal marker we might like):

    print form
        'Hyperspatial',
        '_____________',
        '{] ]]] ]]]:[}',
         \@nums;

to produce:

    Hyperspatial
    _____________
             0:0
             1:0
             1:1
             1:23
         4 567:89
        34 567:89
       234 567:89
     1 234 567:89

You can also put separators in a regular C<{>>>>>>>}> or C<{]]]]]]]}> field,
to print integers with (say) commas:

    print form
        'Integral',
        '___________',
        '{]],]]],]]}',
         \@nums;

which produces:

    Integral
    ___________
              0
              1
              1
              1
          4,568
         34,568
        234,568
      1,234,568

Notice that the numbers are still rounded; in this case, to integers.


=head1 Locale-specific numeric formatting

Of course, sometimes we don't know ahead of time just where in the world our
formatted numbers will be displayed. Locales were invented to address that
very problem, and C<form> supports them.

If we use the C<locale> option, C<form> detects the current locale and
converts any numerical formats it finds to the appropriate layout. For
example, if we wrote:

    @nums = ( 1, -1.2,  1.23, -11.234,  111.235, -12345.67);

    print form
            '{],]]],]]].[[}',
            \@nums;

then we'd get:

          1.0
         -1.2
          1.23
        -11.234
        111.235
    -12,345.67

wherever the program was run. But if we had written:

    print form
            {locale=>1},
            '{],]]],]]].[[}',
            \@nums;

then we'd get:

          1.0
         -1.2
          1.23
        -11.234
        111.235
    -12,345.67

or:

          1,0
          1,2-
          1,23
         11,23-
        111,235
     12.345,67-

or:

          1,0
         (1,2)
          1,23
        (11,23)
        111,235
    (12'345,67)

or whatever else the current locale indicated was the correct local layout
for numbers.

That is, when the C<locale> option is specified, C<form> ignores the actual
decimal point, thousands separator, and negation sign we specified in the call,
and instead uses the values for these markers that are returned by the
POSIX C<localeconv> function. That means that we can specify our numerical
formatting in a style that seems natural to us, and at the same time
allow the numbers to be formatted in a style that seems natural to the user.


=head1 Currency fields

Formatting numbers gets even trickier when those numbers represent money.
But C<form> simply lets us specify how the local currency looks E<ndash>
including leading, trailing, or infix currency markers; leading, trailing, or
circumfix negation markers; thousands separators; etc. E<ndash> and then it
formats it that way. For example:

    my @amounts = (0, 1, 1.2345, 1234.56, -1234.56, 1234567.89);

    my %format = (
        'Canadian (English)'    => q/   {-$],]]],]]].[}/,
        'Canadian (French)'     => q/    {-] ]]] ]]],[ $}/,
        'Dutch'                 => q/     {],]]],]]].[-EUR}/,
        'German (pre-euro)'     => q/    {-].]]].]]],[DM}/,
        'Indian'                => q/    {-]],]],]]].[ Rs}/,
        'Norwegian'             => q/ {kr -].]]].]]],[}/,
        'Portuguese (pre-euro)' => q/    {-].]]].]]]$[ Esc}/,
        'Swiss'                 => q/{Sfr -]']]]']]].[}/,
    );

    for my $nationality (keys %format) {
        my $layout = $format{$nationality};
        print form "$nationality:",
                   "    $layout",
                        \@amounts,
                   "\n";
    }

produces:

    Swiss:
                  Sfr 0.0
                  Sfr 1.0
                  Sfr 1.23
              Sfr 1'234.56
             Sfr -1'234.56
          Sfr 1'234'567.89

    Canadian (French):
                      0,0 $
                      1,0 $
                      1,23 $
                  1 234,56 $
                 -1 234,56 $
              1 234 567,89 $

    Dutch:
                      0.0EUR
                      1.0EUR
                      1.23EUR
                  1,234.56EUR
                  1,234.56-EUR
              1,234,567.89EUR

    Norwegian:
                   kr 0,0
                   kr 1,0
                   kr 1,23
               kr 1.234,56
              kr -1.234,56
           kr 1.234.567,89

    German (pre-euro):
                      0,0DM
                      1,0DM
                      1,23DM
                  1.234,56DM
                 -1.234,56DM
              1.234.567,89DM

    Indian:
                      0.0 Rs
                      1.0 Rs
                      1.23 Rs
                  1,234.56 Rs
                 -1,234.56 Rs
              12,34,567.89 Rs

    Portuguese (pre-euro):
                      0$0 Esc
                      1$0 Esc
                      1$23 Esc
                  1.234$56 Esc
                 -1.234$56 Esc
              1.234.567$89 Esc

    Canadian (English):
                     $0.0
                     $1.0
                     $1.23
                 $1,234.56
                -$1,234.56
             $1,234,567.89


=head1 Verbatim fields

Sometimes all we want is an existing block
of data laid out into columns E<ndash> without any fancy reformatting
or rejustification. For example, suppose we have an interesting string
like this:

    $diagram = <<EODNA;
       G==C
         A==T
           T=A
           A=T
         T==A
       G===C
      T==A
     C=G
    TA
    AT
     A=T
      T==A
        G===C
          T==A
    EODNA

and we'd like to put beside some other text. Because it's already carefully
formatted, we really don't want to interpolate it into a left-justified field:

    print form
        '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {[[[[[[[[[[[[[[[}',
         $diatribe,                                        $diagram;

Because that would squash our lovely helix:

    Men at  some  time  are  masters  of  their       G==C
    fates: / the fault, dear Brutus, is not  in       A==T
    our genes, / but in ourselves, that we  are       T=A
    underlings.  /  Brutus  and  Caesar:   what       A=T
    should be in that 'Caesar'?  /  Why  should       T==A
    that DNA be sequenced more  than  yours?  /       G===C
    Extract them together, yours is as  fair  a       T==A
    genome; / transcribe them, it  doth  become       C=G
    mRNA as well; / recombine them,  it  is  as       TA
    long; clone with 'em, / Brutus will start a       AT
    twin as soon as Caesar. / Now, in the names       A=T
    of all  the  gods  at  once,  /  upon  what       T==A
    proteins doth our Caesar feed, / that he is       G===C
    grown so great?                                   T==A


Nor would right-, full-, centre- or numeric- justification help in this
instance. What we really need is "leave-it-the-hell-alone"
justification E<ndash> a field specifier that lays out the data exactly as it
is, leading whitespace included.

And that's the purpose of a I<verbatim field>. A verbatim single-line field
(C<{'''''''''}>) grabs the next line of data it's offered and inserts as
much of it as will fit in the field's width, preserving whitespace "as
is". Likewise a verbatim block field (C<{"""""""""}>) grabs every line
of the data it's offered and interpolates it into the text without any
reformatting or justification.

And that's precisely what we needed for our diagram:

    print form
        '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {"""""""""""""""}',
         $diatribe,                                        $diagram;

to produce:

    Men at  some  time  are  masters  of  their          G==C
    fates: / the fault, dear Brutus, is not  in            A==T
    our genes, / but in ourselves, that we  are              T=A
    underlings.  /  Brutus  and  Caesar:   what              A=T
    should be in that 'Caesar'?  /  Why  should            T==A
    that DNA be sequenced more  than  yours?  /          G===C
    Extract them together, yours is as  fair  a         T==A
    genome; / transcribe them, it  doth  become        C=G
    mRNA as well; / recombine them,  it  is  as       TA
    long; clone with 'em, / Brutus will start a       AT
    twin as soon as Caesar. / Now, in the names        A=T
    of all  the  gods  at  once,  /  upon  what         T==A
    proteins doth our Caesar feed, / that he is           G===C
    grown so great?                                         T==A

Note that, unlike other types of fields, verbatim fields don't
L<break and wrap their data|"A man may break a word with you, sir...">
if that data doesn't fit on a single line. Instead, they truncate each line to
the appropriate field width. So a too-short verbatim field:

    print form
        '{[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]}       {""""""}',
         $diatribe,                                        $diagram;

results in gene slicing:

    Men at  some  time  are  masters  of  their          G==C
    fates: / the fault, dear Brutus, is not  in            A==
    our genes, / but in ourselves, that we  are              T
    underlings.  /  Brutus  and  Caesar:   what              A
    should be in that 'Caesar'?  /  Why  should            T==
    that DNA be sequenced more  than  yours?  /          G===C
    Extract them together, yours is as  fair  a         T==A
    genome; / transcribe them, it  doth  become        C=G
    mRNA as well; / recombine them,  it  is  as       TA
    long; clone with 'em, / Brutus will start a       AT
    twin as soon as Caesar. / Now, in the names        A=T
    of all  the  gods  at  once,  /  upon  what         T==A
    proteins doth our Caesar feed, / that he is           G===
    grown so great?                                         T=

rather than teratogenesis:

    Men at  some  time  are  masters  of  their          G==C
    fates: / the fault, dear Brutus, is not  in            A=-
    our genes, / but in ourselves, that we  are       =T
    underlings.  /  Brutus  and  Caesar:   what              -
    should be in that 'Caesar'?  /  Why  should       T=A
    that DNA be sequenced more  than  yours?  /              -
    Extract them together, yours is as  fair  a       A=T
    genome; / transcribe them, it  doth  become            T=-
    mRNA as well; / recombine them,  it  is  as       =A
    long; clone with 'em, / Brutus will start a          G===C
    twin as soon as Caesar. / Now, in the names         T==A
    of all  the  gods  at  once,  /  upon  what        C=G
    proteins doth our Caesar feed, / that he is       TA
    grown so great?                                  AT
                                                   A=T
                                                    T==A
                                                      G==-
                                                  =C
                                                        T-
                                                  ==A


=head1 Overflow fields

It's not uncommon for a report to need a series of data fields in one
column and then a second column with only single field, perhaps
containing a summary or discussion of the other data. For example,
we might want to produce recipes of the form:

    =================[  Hecate's Broth of Ambition  ]=================

      Preparation time:             Method:
         66.6 minutes                  Remove the legs from the
                                       lizard, the wings from the
      Serves:                          owlet, and the tongue of the
         2 doomed souls                adder. Set them aside.
                                       Refrigerate the remains (they
      Ingredients:                     can be used to make a lovely
         2 snakes (1 fenny, 1          white-meat stock). Drain the
         adder)                        newts' eyes if using pickled.
         2 lizards (1 legless,         Wrap the toad toes in the
         1 regular)                    bat's wool and immerse in half
         3 eyes of newt (fresh         a pint of vegan stock in
         or pickled)                   bottom of a preheated
         2 toad toes (canned           cauldron. (If you can't get a
         are fine)                     fresh vegan for the stock, a
         2 cups of bat's wool          cup of boiling water poured
         1 dog tongue                  over a vegetarian holding a
         1 common or spotted           sprouted onion will do). Toss
         owlet                         in the fenny snake, then the
                                       legless lizard. Puree the
                                       tongues together and fold
                                       gradually into the mixture,
                                       stirring widdershins at all
                                       times.  Allow to bubble for 45
                                       minutes then decant into two
                                       tarnished copper chalices.
                                       Garnish each with an owlet
                                       wing, and serve immediately.


There are several ways to achieve that effect. The most obvious is to
format each column separately and then lay them out side-by-side
with a pair of verbatim fields:

    my $prep = form 'Preparation time:        ',
                    '   {<<<<<<<<<<<<<<<<<<<<}', $prep_time,
                    '                         ',
                    'Serves:                  ',
                    '   {<<<<<<<<<<<<<<<<<<<<}', $serves,
                    '                         ',
                    'Ingredients:             ',
                    '   {[[[[[[[[[[[[[[[[[[[[}', $ingredients;

    my $make = form 'Method:                          ',
                    '   {[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
                        $method;

    print form
        '=================[ {||||||||||||||||||||||||||} ]=================',
                                      $recipe,
        '                                                                  ',
        '  {"""""""""""""""""""""""}     {"""""""""""""""""""""""""""""""} ',
           $prep,                        $make;


We could even chain the calls to C<form> to eliminate the interim variables:

    print form
        '=================[ {||||||||||||||||||||||||||} ]=================',
                                      $recipe,
        '                                                                  ',
        '  {"""""""""""""""""""""""}     {"""""""""""""""""""""""""""""""} ',
           form('Preparation time:        ',
                '   {<<<<<<<<<<<<<<<<<<<<}', $prep_time,
                '                         ',
                'Serves:                  ',
                '   {<<<<<<<<<<<<<<<<<<<<}', $serves
                '                         ',
                'Ingredients:             ',
                '   {[[[[[[[[[[[[[[[[[[[[}', $ingredients,
               ),
           form('Method:                          ',
                '   {[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
                    $method,
               );

While it's impressive to be able to do that kind of nested formatting
(and highly useful in extreme formatting scenarios), it's also far too
ungainly for regular use. A cleaner, more maintainable solution is
use a single format and just build the method column up
piecemeal, like so:

    print form
        '=================[ {||||||||||||||||||||||||||} ]=================',
                                      $recipe,
        '                                                                  ',
        'Preparation time:               Method:                           ',
        '   {<<<<<<<<<<<<<<<<<<<<}          {<<<<<<<<<<<<<<<<<<<<<<<<<<<:} ',
            $prep_time,                     $method,
        '                                   {:<<<<<<<<<<<<<<<<<<<<<<<<<<:} ',
                                            $method,
        'Serves:                            {:<<<<<<<<<<<<<<<<<<<<<<<<<<:} ',
                                            $method,
        '   {<<<<<<<<<<<<<<<<<<<<}          {:<<<<<<<<<<<<<<<<<<<<<<<<<<:} ',
            $serves,                        $method,
        '                                   {:<<<<<<<<<<<<<<<<<<<<<<<<<<:} ',
                                            $method,
        'Ingredients:                       {:<<<<<<<<<<<<<<<<<<<<<<<<<<:} ',
                                            $method,
        '   {[[[[[[[[[[[[[[[[[[[[}          {:[[[[[[[[[[[[[[[[[[[[[[[[[[[} ',
            $ingredients,                   $method;


That produces exactly the same result as the previous versions, because
each follow-on C<<<< {:<<<<<<<:} >>>> field in the
"Method" column grabs one extra line from C<$method>, and then the final
follow-on C<{:[[[[[[}> field grabs as many more as are required
to lay out the rest of the contents of the variable. The only down-side is
that the resulting code is still downright ugly. With all those tedious
repetitions of the same variable, there's far too much C<$method>
in our madness.

Having a series of follow-on fields like this E<ndash> vertically
continuing a single column across subsequent format lines E<ndash> is so
common that C<form> provides a special shortcut: the C<{VVVVVVVVV}>
I<overflow field>.

An overflow field automagically duplicates the field specification
immediately above it. The important point being that, because that
duplication includes copying the preceding field's data source, overflow
fields don't require a separate data source of their own.

Using overflow fields, we could rewrite our quotation generator
like this:

    print form
        '=================[ {||||||||||||||||||||||||||} ]=================',
                                      $recipe,
        '                                                                  ',
        'Preparation time:               Method:                           ',
        '   {<<<<<<<<<<<<<<<<<<<<}          {<<<<<<<<<<<<<<<<<<<<<<<<<<<<} ',
            $prep_time,                     $method,
        '                                   {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
        'Serves:                            {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
        '   {<<<<<<<<<<<<<<<<<<<<}          {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
            $serves,
        '                                   {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
        'Ingredients:                       {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
        '   {[[[[[[[[[[[[[[[[[[[[}          {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ',
            $ingredients,
        '                                   {VVVVVVVVVVVVVVVVVVVVVVVVVVVV} ';

Which would once again produce the recipe shown earlier.

Note that the overflow fields interact equally well in formats with
single-line and block fields. That's because block overflow fields have
one other special feature: they're non-greedy. Unless we L<specify
otherwise|"Height control">, all types of block
fields will consume their entire data source. For example, if we wrote:

    print form {layout=>"across"},
         '{<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>:}',
                                  $speech,
         '{:<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>:}',
                                  $speech,
         '{:[[[[[]]]]]:}   {="""""""""""""""""""=}   {:[[[[[]]]]]]:}',
             $speech,             $advert,              $speech,
         '{:[[[[[[[[[[[[[[[[[[[[[[[[[]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]}',
                                  $speech;

we'd get:

    Now is the winter of our discontent / Made glorious summer
    by this sun of York; / And all the clouds that lour'd upon
    our house / In                             the deep  bosom
    of  the  ocean                             buried.  /  Now
    are our  brows                             bound      with
    victorious                                 wreaths; /  Our
    bruised   arms                             hung   up   for
    monuments;   /                             Our       stern
    alarums          +---------------------+   changed      to
    merry            |                     |   meetings, / Our
    dreadful         | Eat at Mrs Miggins! |   marches      to
    delightful       |                     |   measures. Grim-
    visaged    war   +---------------------+   hath   smooth'd
    his   wrinkled                             front;  /   And
    now,   instead                             of     mounting
    barded  steeds                             / To fright the
    souls       of                             fearful
    adversaries, /                             He       capers
    nimbly  in   a                             lady's chamber.

That's because the two C<{:[[[[[]]]]]:}> block fields
on either side of the verbatim advertisement field will eat all the
data in C<$speech>, leaving nothing for the final format. Then
the advertisement will be centred on the two resulting columns of text.

But, block overflow fields are different.
They only take as many lines as are required to
fill the lines generated by the non-overflow fields in their format.
So, if we changed our code to use overflows:

    print form {layout=>"across"},
         '{<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>}', $speech,
         '{VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
         '{VVVVVVVVVVVV}   {="""""""""""""""""""=}   {VVVVVVVVVVVVV}', $advert,
         '{VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}';

we get both a cleaner specification and a more elegant result:

    Now is the winter of our discontent / Made glorious summer
    by this sun of York; / And all the clouds that lour'd upon
    our house / In                             the deep  bosom
    of  the  ocean   +---------------------+   buried.  /  Now
    are our  brows   |                     |   bound      with
    victorious       | Eat at Mrs Miggins! |   wreaths; /  Our
    bruised   arms   |                     |   hung   up   for
    monuments;   /   +---------------------+   Our       stern
    alarums                                    changed      to
    merry meetings,  /  Our  dreadful  marches  to  delightful
    measures. Grim-visaged  war  hath  smooth'd  his  wrinkled
    front; / And now, instead of mounting barded steeds  /  To
    fright the souls  of  fearful  adversaries,  /  He  capers
    nimbly in a lady's chamber.

Notice that, in the third format line of the previous example, the two
overflow fields on either side of the advertisement are each overflowing
from the single field that's above both of them. This kind of multiple
overflow is fine, but it does require that we specify I<how> the various
fields overflow (i.e. as two separate columns of text, or E<ndash> as in
this case E<ndash> as a single, broken column across the page). That's
the purpose of the C<layout> option on the
first line. This option is explained in detail L<below|"Layout control">.

The C<{VVVVVVVV}> fields only consumed as much data from C<$speech> as
was required to sandwich the output lines created by the verbatim
advertisement. This feature is important, because it means we can lay
out a series of block fields in one column and a single overflowed field
in another column without introducing ugly gaps. For example, because
the C<{VVVVVVVVV}> fields in:

    print form
        'Name:                                                  ',
        '  {[[[[[[[[[[[[}                                       ', $name,
        '                  Biography:                           ',
        'Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}', $bio,
        '  {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}', $status,
        '                    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        'Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        '  {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}', $comments;

only consume as much of the overflowing C<$bio> field as necessary,
the result is something like:

    Name:
      William
      Shakespeare
                      Biography:
    Status:             William Shakespeare was born on
      Deceased (1564    April 23, 1564 in Strathford-upon-
      -1616)            Avon, England; he was third of
                        eight children from Father John
    Comments:           Shakespeare and Mother Mary Arden.
      Theories          Shakespeare began his education at
      abound as to      the age of seven when he probably
      the true          attended the Strathford grammar
      author of his     school. The school provided
      plays. The        Shakespeare with his formal
      prime             education. The students chiefly
      alternative       studied Latin rhetoric, logic, and
      candidates        literature. His knowledge and
      being Sir         imagination may have come from his
      Francis           reading of ancient authors and
      Bacon,            poetry. In November 1582,
      Christopher       Shakespeare received a license to
      Marlowe, or       marry Anne Hathaway. At the time of
      Edward de         their marriage, Shakespeare was 18
      Vere              years old and Anne was 26. They had
                        three children, the oldest Susanna,
                        and twins- a boy, Hamneth, and a
                        girl, Judith. Before his death on
                        April 23 1616, William Shakespeare
                        had written thirty-seven plays. He
                        is generally considered the
                        greatest playwright the world has
                        ever known and has always been the
                        world's most popular author.

If C<{VVVVVVVVVVV}> fields ate their entire data E<ndash> the way
C<{[[[[[[[[[}> or C<{IIIIIIIIII}> fields do E<ndash> then the output would be
much less satisfactory. The first block overflow field for C<$bio> would
have to consume the entire biography, before the comments field was even
reached. So our output would be something like:

    Name:
      William
      Shakespeare
                      Biography:
    Status:             William Shakespeare was born on
      Deceased (1564    April 23, 1564 in Strathford-upon-
      -1616)            Avon, England; he was third of
                        eight children from Father John
                        Shakespeare and Mother Mary Arden.
                        Shakespeare began his education at
                        the age of seven when he probably
                        attended the Strathford grammar
                        school. The school provided
                        Shakespeare with his formal
                        education. The students chiefly
                        studied Latin rhetoric, logic, and
                        literature. His knowledge and
                        imagination may have come from his
                        reading of ancient authors and
                        poetry. In November 1582,
                        Shakespeare received a license to
                        marry Anne Hathaway. At the time of
                        their marriage, Shakespeare was 18
                        years old and Anne was 26. They had
                        three children, the oldest Susanna,
                        and twins- a boy, Hamneth, and a
                        girl, Judith. Before his death on
                        April 23 1616, William Shakespeare
                        had written thirty-seven plays. He
                        is generally considered the
                        greatest playwright the world has
                        ever known and has always been the
                        world's most popular author.

    Comments:
      Theories
      abound as to
      the true
      author of his
      plays. The
      prime
      alternative
      candidates
      being Sir
      Francis
      Bacon,
      Christopher
      Marlowe, or
      Edward de
      Vere

Which is precisely why C<{VVVVVVVVVVV}> fields don't work that way.



=head2 Line-breaking

Whenever a field is passed more data than it can
accommodate in a single line, C<form> is forced to "break" that data somewhere.

If the field in question is I<W>
columns wide, C<form> first squeezes any whitespace (as specified by
the L<user's C<ws> option|"Whitespace squeezing">) and then looks at the next I<W> columns of the string.

C<form>'s breaking algorithm then searches for a newline, a carriage
return, any other whitespace character, or a hyphen. If it
finds a newline or carriage return within the first I<W> columns, it
immediately breaks the data string at that point. Otherwise it locates
the I<last> whitespace or hyphen in the first I<W> columns and breaks
the string immediately after that space or hyphen. If it can't find
anywhere suitable to break the string, it breaks it at the (I<W>-1)th
column and appends a hyphen.

So, for example:

    $data = "You can play no part but Pyramus;\nfor Pyramus is a sweet-faced man";

    print form "|{[[[[[}|",
                 $data;

prints:

    |You can|
    |play no|
    |part   |
    |but    |
    |Pyramu-|
    |s;     |
    |for    |
    |Pyramus|
    |is a   |
    |sweet- |
    |faced  |
    |man    |

Note the line-breaks after I<can> (at a whitespace), I<part> (after a
whitespace), I<sweet-> (after a hyphen), and I<s;> (at a newline). Note
too that I<Pyramus;> doesn't fit in the field, so it has to be chopped in two
and a hyphen inserted.

Of course, this particular style of line-breaking may not be suitable to all
applications, and we might prefer that C<form> use some other algorithm. For
example, if C<form> used the TeX breaking algorithm it would have broken
I<Pyramus;> less clumsily, yielding:

    |You can|
    |play no|
    |part   |
    |but    |
    |Pyra-  |
    |mus;   |
    |for    |
    |Pyramus|
    |is a   |
    |sweet- |
    |faced  |
    |man    |


To support different line-breaking strategies C<form> provides
the C<break> option.  The C<break> option's value must be
a closure/subroutine, which will then be called whenever a data string
needs to be broken to fit a particular field width.

That subroutine is passed three arguments: a reference to the data
string itself, an integer specifying how wide the field is, and a regex
indicating which (if any) characters are to be
L<squeezed|"Whitespace squeezing">.
It is expected to return a list of two values: a string which is taken
as the "broken" text for the field, and a boolean value indicating
whether or not any data remains after the break (so C<form> knows when
to stop breaking the data string). The subroutine is also expected to
update the C<.pos> of the data string to point immediately after the
break it has imposed.

For example, if we always wanted to break at the exact width of the field
(with no hyphens), we could do that with:

    sub break_width {
        my ($data_ref, $width, $ws) = @_;
        for ($$data_ref) {
            # Treat any squeezed or vertical whitespace as a single character
            # (since they'll subsequently be squeezed to a single space)
            my $single_char = qr{ $ws | [\n\r]+ | . }

            # Give up if there are no more characters to grab...
            return ("", 0) unless m/\G (single_char{1,$width}) /gcx;

            # Squeeze the resultant substring...
            (my $result = $1) =~ s/ $ws | [\n\r] / /gx;

            # Check for any more data still to come...
            my $more = m/\G (?= .* \S) /gcx;

            # Return the squeezed substring and the "more" indicator...
            return ($result, $more);
        }
    }

    print form
        {break=>\&break_width},
        '|{[[[[[}|',
          $data;

producing:

    |You can|
    |play no|
    |part bu|
    |t Pyram|
    |us; for|
    |Pyramus|
    |is a sw|
    |eet-fac|
    |ed man |

Or we might prefer to break on every single whitespace-separated word:

    sub break_word {
        my ($data_ref, $width, $ws) = @_;
        for ($$data_ref) {
            # Locate the next word (no longer than $width cols)
            my $found = m/\G \s* (\S{1,$width}) /gcx;

            # Fail if no more words...
            return ("", 0) unless $found;
            my $word = $1;

            # Check for any more data still to come...
            my bool $more = m/\G (?= .* \S) /gcx;

            # Otherwise, return broken text and "more" flag...
            return ($word, $more);
        }
    }

    print form
        {break=>\&break_word},
        '|{[[[[[}|',
          $data;

producing:

    |You    |
    |can    |
    |play   |
    |no     |
    |part   |
    |but    |
    |Pyramus|
    |;      |
    |for    |
    |Pyramus|
    |is     |
    |a      |
    |sweet-f|
    |aced   |
    |man    |


We'll see yet another application of user-defined breaking when
we discuss L<user-defined fields|"User-defined fields">.


=head2 Interleaving data

There are (at least) three schools of thought when it comes to setting
out a call to C<form> that uses more than one format. The
"traditional" way (i.e. the way Perl 5 formats do it) is to interleave
each format string with a line containing the data it is to
interpolate, with each datum aligned directly under the field into
which it is to be fitted. Like so:

    print form
        'Name:                                                  ',
        '  {[[[[[[[[[[[[}                                       ',
           $name,
        '                  Biography:                           ',
        'Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}',
                             $bio,
        '  {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
           $status,
        '                    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        'Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        '  {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
           $comments;

This approach has the advantage that it self-documents: to know what
a particular field is supposed to contain, we merely need to look
down one line.

It does, however, break up the "abstract picture" that the formats
portray, which can make it more difficult to envisage what the final
formatted text will look like. So some people prefer to put all the data
to the right of the formats:

    print form
        'Name:                                                  ',
        '  {[[[[[[[[[[[[}                                       ', $name,
        '                  Biography:                           ',
        'Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}', $bio,
        '  {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}', $status,
        '                    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        'Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        '  {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}', $comments;

And that's perfectly acceptable too.

Sometimes, however, the data to be interpolated doesn't come neatly
pre-packaged in separate variables that are easy to intersperse between the
formats. For example, the data might be a list returned by a
subroutine call (C<get_info($next_person)>) or might be stored in a hash
(S< C<@person{qw( name biog stat comm )}> >). In such
cases it's a nuisance to have to tease that data out into separate
variables (or hash accesses) and then sprinkle them through the formats:

    print form
        'Name:                                                  ',
        '  {[[[[[[[[[[[[}                                       ',$person{name},
        '                  Biography:                           ',
        'Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}',$person{biog},
        '  {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',$person{stat},
        '                    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        'Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',
        '  {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}',$person{comm};

So C<form> has an option that lets us put a single, multi-line format
at the start of the argument list, place all the data together
after it, and have that data automatically interleaved as necessary.
Not surprisingly, that option is: C<interleave>. It's normally used in
conjunction with a heredoc, since that's the easiest way to specify a
multi-line string in Perl:

    print form {interleave=>1}, <<'EOFORMAT',
    Name:
      {[[[[[[[[[[[[}
                      Biography:
    Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}
      {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
                        {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
      {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    EOFORMAT
         @person{qw( name biog stat comm )};

When C<interleave> is in effect, C<form> grabs the first string
argument it's passed and breaks that argument up into individual lines.
It treats those individual lines as a series of distinct formats
and grabs as many of the remaining arguments as are required to
provide data for each format.


=head2 Multi-line formats

It's important to point out that, even when we're using C<form>'s
default B<non>-interleaving behaviour, it's still okay to use a format
that spans multiple lines. There I<is> however a significant (and useful)
difference in behaviour between the two alternatives.

The normal behaviour of C<form> is to take each format string,
fill in each field in the format with a substring from the
corresponding data source, and then repeat that process until all the
data sources have been exhausted. Which means that a multi-line format
like this:

    print form
         <<'EOFORMAT',
    Name:    {[[[[[[[[[[[[[[[}   Role: {[[[[[[[[[[}
    Address: {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}
    _______________________________________________
    EOFORMAT
         \@names, \@roles, \@addresses;

would normally produce this:

    Name:    King Lear           Role: Protagonist
    Address: The Cliffs, Dover
    _______________________________________________
    Name:    The Three Witches   Role: Plot devices
    Address: Dismal Forest, Scotland
    _______________________________________________
    Name:    Iago                Role: Villain
    Address: Casa d'Otello, Venezia
    _______________________________________________

because the entire three-line format is repeatedly filled in
as a single unit, line-by-line and datum-by-datum.

On the other hand, if we tell C<form> that it's supposed to automatically
interleave the data coming after the format, like so:

    print form {interleave=>1},
         <<'EOFORMAT',
    Name:    {[[[[[[[[[[[[[[[}   Role: {[[[[[[[[[[}
    Address: {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}
    _______________________________________________
    EOFORMAT
         \@names, \@roles, \@addresses;

then the call produces:

    Name:    King Lear           Role: Protagonist
    Name:    The Three Witches   Role: Plot devices
    Name:    Iago                Role: Villain
    Address: The Cliffs, Dover
    Address: Dismal Forest, Scotland
    Address: Casa d'Otello, Venezia
    _______________________________________________

because that second version is really equivalent to:

    print form
         'Name:    {[[[[[[[[[[[[[[[}   Role: {[[[[[[[[[[}',
                   \@names,                  \@roles,
         'Address: {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
                   \@addresses,
         '_______________________________________________';


That's not much use in this particular example, but it was exactly what
was needed for the biography example earlier. It's just a matter of
choosing the right type of data placement to achieve the particular
effect we want.


=head2 Layout control

As we saw earlier, with follow-on fields and overflow fields, C<form>
is perfectly happy to have several fields in a single format that
are all fed by the same data source. For example:

    print form
        '{[[[[[[[[]]]]]]]]]]:}   {:[[[[[[[]]]]]]]]]]:}   {:[[[[[[[[]]]]]]]]]]}',
             $soliloquy,             $soliloquy,              $soliloquy;

In fact, that kind of format is particularly useful for creating
multi-column outputs (like newspaper columns, for example).

But a small quandry arises. In what order should C<form> fill in these
fields? Should the data be formatted down the page, filling each column
completely before starting the next (and therefore potentially leaving
the last column "short"):

    Now is the winter  of   torious  wreaths;   /   front; / And now, in-
    our discontent / Made   Our bruised arms hung   stead of mounting ba-
    glorious  summer   by   up for  monuments;  /   rded steeds / To fri-
    this sun of  York;  /   Our stern alarums ch-   ght the souls of fea-
    And  all  the  clouds   anged to merry meeti-   rful  adversaries,  /
    that lour'd upon  our   ngs, /  Our  dreadful   He capers nimbly in a
    house / In  the  deep   marches to delightful   lady's chamber.
    bosom  of  the  ocean   measures.   /   Grim-
    buried. / Now are our   visaged war hath smo-
    brows bound with vic-   oth'd  his   wrinkled

Or should the data be run line-by-line across all three columns (the
way a Perl 5 C<format> does it), filling one line completely before
starting the next:

    Now is the winter  of   our discontent / Made   glorious  summer   by
    this sun of  York;  /   And  all  the  clouds   that lour'd upon  our
    house / In  the  deep   bosom  of  the  ocean   buried. / Now are our
    brows bound with vic-   torious  wreaths;   /   Our bruised arms hung
    up for  monuments;  /   Our stern alarums ch-   anged to merry meeti-
    ngs, /  Our  dreadful   marches to delightful   measures.   /   Grim-
    visaged war hath smo-   oth'd  his   wrinkled   front; / And now, in-
    stead of mounting ba-   rded steeds / To fri-   ght the souls of fea-
    rful  adversaries,  /   He capers nimbly in a   lady's chamber.

Or should the text run down the columns, but in such a way as to leave
those columns as evenly balanced in length as possible:

    Now is the winter  of   brows bound with vic-   visaged war hath smo-
    our discontent / Made   torious  wreaths;   /   oth'd  his   wrinkled
    glorious  summer   by   Our bruised arms hung   front; / And now, in-
    this sun of  York;  /   up for  monuments;  /   stead of mounting ba-
    And  all  the  clouds   Our stern alarums ch-   rded steeds / To fri-
    that lour'd upon  our   anged to merry meeti-   ght the souls of fea-
    house / In  the  deep   ngs, /  Our  dreadful   rful  adversaries,  /
    bosom  of  the  ocean   marches to delightful   He capers nimbly in a
    buried. / Now are our   measures.   /   Grim-   lady's chamber.

Well, of course, there's no "right" answer to that; it depends entirely
on what kind of effect we're trying to achieve.

The first approach (i.e. lay out the text down each column first) works
well if we're formatting a news-column, or a report, or a description of
some kind. The second (i.e. lay out the text across each line first), is
excellent for putting diagrams or call-outs in the middle of a piece of
text (as we did for L<Mrs Miggins|"Overflow fields">).
The third approach (i.e. lay out the data downwards but
balance the columns) is best for presenting a single list of data in
multiple columns E<ndash> like C<ls> does.

So we need an option with which to tell C<form> which of these useful
alternatives we want for a particular format. That option is named
C<layout> and can take one of three string values: C<"down">, C<"across">,
or C<"balanced">. So, for example, to produce three versions of Richard III's
famous monologue in the order shown above, we'd use:

    print form {layout=>"down"},
        '{[[[[[[[[]]]]]]]]]]:}   {:[[[[[[[]]]]]]]]]]:}   {:[[[[[[[[]]]]]]]]]]}',
             $soliloquy,             $soliloquy,              $soliloquy;

then:

    print form {layout=>"across"},
        '{[[[[[[[[]]]]]]]]]]:}   {:[[[[[[[]]]]]]]]]]:}   {:[[[[[[[[]]]]]]]]]]}',
             $soliloquy,             $soliloquy,              $soliloquy;

then:

    print form {layout=>"balanced"},
        '{[[[[[[[[]]]]]]]]]]:}   {:[[[[[[[]]]]]]]]]]:}   {:[[[[[[[[]]]]]]]]]]}',
             $soliloquy,             $soliloquy,              $soliloquy;

By the way, the default value for the C<layout> option is C<"balanced">
since formatting regular columns of data is more common than formatting
news or advertising inserts.


=head2 Tabular layout

The C<layout> option controls one other form of inter-column formatting:
tabular layout.

So far, all the examples of tables we've created (for example, our
L<normalized scores|"Array data sources">)
lined up nicely. But that was only because each item in each row
happened to take the same number of lines (typically just one).
So, a table generator like this:

    my @play = map {"$_\r"}  ( "Othello", "Richard III", "Hamlet"   );
    my @name = map {"$_\r"}  ( "Iago",    "Henry",       "Claudius" );

    print form
         'Character       Appears in  ',
         '____________    ____________',
         '{[[[[[[[[[[}    {[[[[[[[[[[}',
          \@name,         \@play;

correctly produces:

    Character       Appears in
    ____________    ____________
    Iago            Othello

    Henry           Richard III

    Claudius        Hamlet

Note that we appended C<"\r"> to each element to add an extra
newline after each entry in the table. We can't use C<"\n"> to specify a
line-break within an array element, because C<form> uses C<"\n"> as an
L<"end-of-element" marker|"Therefore, put you in your best array...">.
So, to allow line breaks within a single element of an array datum,
C<form> treats C<"\r"> as "end-of-line-but-not-end-of-element"
(somewhat like Perl 5's C<format> does).

However, if we were to use the full titles for each character and each play:

    my @play = map {"$_\r"}  ( "Othello, The Moor of Venice",
                               "The Life and Death of King Richard III",
                               "Hamlet, Prince of Denmark",
                             );

    my @name = map {"$_\r"}  ( "Iago",
                               "Henry,\rEarl of Richmond",
                               "Claudius,\rKing of Denmark",
                             );

the same formatter would produce:

    Character       Appears in
    ____________    ____________
    Iago            Othello, The
                    Moor of
    Henry,          Venice
    Earl of
    Richmond        The Life and
                    Death of
    Claudius,       King Richard
    King of         III
    Denmark
                    Hamlet,
                    Prince of
                    Denmark

The problem is that the two block fields we're using just grab all
the data from each array and format it independently into each column.
Usually that's fine because the columns I<are> independent (as we've
L<previously seen|"Verbatim fields">).

But in a table, the data in each column specifically relates to data
in other columns, so corresponding elements from the column's data
arrays ought to remain vertically aligned. To achieve this, we simply
tell C<form> that the data in the various columns should be laid out
like a table:

    print form {layout=>"tabular"},
         'Character       Appears in  ',
         '____________    ____________',
         '{[[[[[[[[[[}    {[[[[[[[[[[}',
          \@name,         \@play;

which then produces the desired result:

    Character       Appears in
    ____________    ____________
    Iago            Othello, The
                    Moor of
                    Venice

    Henry,          The Life and
    Earl of         Death of
    Richmond        King Richard
                    III

    Claudius,       Hamlet,
    King of         Prince of
    Denmark         Denmark


=head1 Give him line and scope...

Sometimes we want to use a particular option or combination of options
in every call we make to C<form>. Or, more likely, in every call we make
within a specific scope.  For example, we might wish to default to
a different line-breaking algorithm
everywhere, or we might want to make repeated use of
L<a new type of field specifier|"User-defined fields">,
or we might want to L<reset the standard page length|"Page dimensions">
from a printable 60 to a screenable 24.

So the Perl6::Form module provides a mechanism by which options can be prebound.
To use it, we (re-)load the module with an explicit argument list:

    use Form { layout=>"down", locale=>1, interleave=>1 };

This causes the module to export a modified version of C<form> in which the
specified options are prebound.  That modified version of C<form> takes effect
from the line following the C<use> statement, until the end of the current
package (or another C<use Perl6::Form> statement). The effect is B<not>
truly lexical (as it would be in Perl 6).

These default options are handy if we have a series of calls
to C<form> that all need some consistent non-standard behaviour.
For example:

    use Form { layout=>"across",
               interleave=>1,
               page => { header => "Draft $(localtime)\n\n" },
             };

    print form $introduction_format, \@introduction_data;

    while ($format, @data = get_next) {
        print form $format, @data;
    }

    print form $conclusion_format, \@conclusion_data;


=head2 Declarative field widths

When specific field widths are required (perhaps by some design document
or data formatting protocol) laying out wide fields can be error-prone.
For example, most people can't visually distinguish between a
52-column field and a 53-column field and are therefore forced to manually
verify the width of the corresponding field specifier in some way.

To catch mistakes of this kind, fields can be specified with an
embedded integer in parentheses (with optional whitespace inside the
parens). For example:

    print form '{[[[( 15 )[[[[} {<<<<<(17)<<<<<<}  {]]](14)]]].[[}',
               $problem,        $ID,               $description;

The integer in the parentheses acts like a checksum. Its value
must be identical to the actual width of the field (including the
delimiting braces and the embedded integer itself). Otherwise an
exception is thrown. For instance, running the above example produces
the error message:

    Inconsistent width for field 3.
    Specified as '{]]](14)]]].[[}' but actual width is 15
    in call to &form at demo.pl line 1

Numeric fields can be given a decimal checksum, which then also
specifies their number of decimal places.

    print form
        '{[[[( 15 )[[[[} {<<<<<(17)<<<<<<}  {]](14.2)]].[}',
        $problem,        $ID,               $description;

Note that the digits before the decimal still indicate
the total width of the field. So the C<{]](14.2)]].[}> field
in the above example means I<must be 14 columns wide, including
2 decimal places>, in exactly the same way as a C<"%14.2f">
specifier would in a C<sprintf>.


=head2 Imperative field widths

Of course, in some instances it would be much more convenient if we
could simply I<tell> C<form> that we want a particular field to be
a particular width, instead of having to explicitly I<show> it.

So there's another type of integer field annotation that, instead of
acting like a checksum, acts like an...err..."tellsum". That is, we
can tell C<form> to ignore a field's physical width and instead
insist that it be magically expanded (or shrunk) to a nominated width. Such
a field is said to have an I<imperative width>. The integer specifying
the imperative width is placed in curly braces instead of parens.

For example, the format in the previous example could be specified
imperatively as:

    print form
        '{[{15}[} {<{17}<<}  {]]]]{14.2}]]]].[[}',
        $problem, $ID,       $description;

Note that the actual width of any field becomes irrelevant if it
contains an imperative width. The field will be condensed or expanded to
the specified width, with subsequent fields pushed left or right
accordingly.


=head2 Distributive field widths

A special form of imperative width field is the I<starred field>.
A starred field is one that contains an imperative width
specification in which the number is replaced by a single asterisk.

The width of a starred field is not fixed, but rather is I<computed>
during formatting. That width is whatever is required to cause the
entire format to fill the current page width of the format (by default,
78 columns). Consider, for example:

    print form
        '{]]]]]]]]]]]]]]} {]]].[[}  {[[{*}[[}  ',
         \@names,         \@scores, \@comments;

The width of the starred comment field in this case is 49 columns E<ndash>
the default page width of 78 columns minus the 29 columns
consumed by the fixed-width portions of the format (including the other two
fields).

If a format contains two or more starred fields, the available space
is shared equally between them. So, for example, to create two equal columns
(say, to compare the contents of two files), we might use:

    use Perl6::Slurp;

    print form
         '{[[[[{*}[[[[}   {[[[[{*}[[[[}',
          slurp($file1),  slurp($file2);

(And, yes, Perl 6 does have a built-in C<slurp> function that takes a filename,
opens the file, reads in the entire contents, and returns them as a single
string. For more details see the Perl6::Slurp module E<ndash> now on the CPAN.)

There is one special case for starred fields: a starred verbatim field:

    {""""{*}""""}

It acts like any other starred field, growing according to the available
space, except that it will never grow any wider than the widest line
of the data it is formatting. For example, whereas a regular starred
field:

    print form
         '| {[[{*}[[} |',
            $monologue;

expands to the full page width:

    | Now is the winter of our discontent                           |
    | Made glorious summer by this sun of York;                     |
    | And all the clouds that lour'd upon our house                 |
    | In the deep bosom of the ocean buried.                        |
    | Now are our brows bound with victorious wreaths               |
    | Our bruised arms hung up for monuments;                       |
    | Our stern alarums changed to merry meetings,                  |
    | Our dreadful marches to delightful measures.                  |
    | Grim-visaged war hath smooth'd his wrinkled front;            |
    | And now, instead of mounting barded steeds                    |
    | To fright the souls of fearful adversaries,                   |
    | He capers nimbly in a lady's chamber.                         |


a starred verbatim field:

    print form
         '| {""{*}""} |',
            $monologue;

only expands as much as is strictly necessary to accommodate the data:

    | Now is the winter of our discontent                |
    | Made glorious summer by this sun of York;          |
    | And all the clouds that lour'd upon our house      |
    | In the deep bosom of the ocean buried.             |
    | Now are our brows bound with victorious wreaths;   |
    | Our bruised arms hung up for monuments;            |
    | Our stern alarums changed to merry meetings,       |
    | Our dreadful marches to delightful measures.       |
    | Grim-visaged war hath smooth'd his wrinkled front; |
    | And now, instead of mounting barded steeds         |
    | To fright the souls of fearful adversaries,        |
    | He capers nimbly in a lady's chamber.              |


=head2 Extensible fields

By now you've probably noticed that there is quite a large overlap between the
functionality of C<form> and that of C<(s)printf>. For example, the call:

    for (@procs) {
        print form
            '{>>>}  {<<<<<<<(20)<<<<<<<}  {>>>>>>}  {>>.}%',
            $_->{pid}, $_->{cmd},         $_->{time}, $_->{cpu};
    }

has approximately the same effect as the call:

    for (@procs) {
        printf "%5d  %-20s  %8s  %5.1f%%\n",
               $_->{pid}, $_->{cmd}, $_->{time}, $_->{cpu};
    }

One is more WYSIWYG, the other more concise, but (placed in a suitable loop),
they would both print out lines like these:

     2461  vi -ii henry           0:55.83   11.6%
     2395  ex cathedra            0:06.59    3.5%
     2439  head anne.boleyn       0:00.18    0.1%
     2581  dig -short grave       0:01.04    0.0%

There is, however, a crucial difference between these two formatting
facilities; one that only shows up when one of our processes runs over 99
hours. For example, suppose our browser has been running continuously
for a few months (or, more precisely, for 1214:23.75 hours). Then the
calls to C<printf> would print:

     2461  vi -ii henry           0:55.83   11.6%
     2395  ex cathedra            0:06.59    3.5%
    27384  lynx www.divorce.com  1214:23.75    0.8%
     2439  head anne.boleyn       0:00.18    0.1%
     2581  dig -short grave       0:01.04    0.0%

whilst the calls to C<form> would print:

     2461  vi -ii henry           0:55.83   11.6%
     2395  ex cathedra            0:06.59    3.5%
    27384  lynx www.divorce.com  1214:23-    0.8%
     2439  head anne.boleyn       0:00.18    0.1%
     2581  dig -short grave       0:01.04    0.0%

In other words, field widths in a C<printf> represent I<minimal> spacing
(even if that throws off the overall layout), whereas field widths in a
C<form> represent I<guaranteed> spacing (even if that truncates some of
the data).

Of course, in a situation like this E<ndash> where we knew that the data might
not fit and we didn't want it truncated E<ndash> we could use a block field
instead:

    for (@procs) {
        print form
            '{>>>}  {<<<<<<<(19)<<<<<<}  {]]]]]]}  {>>.%}',
            $_->{pid}, $_->{cmd},        $_->{time},  $_->{cpu};
    }

in which case we'd get:

     2461  vi -ii henry           0:55.83   11.6%
     2395  ex cathedra            0:06.59    3.5%
    27384  lynx www.divorce.com  1214:23-    0.8%
                                      .75
     2439  head anne.boleyn       0:00.18    0.1%
     2581  dig -short grave       0:01.04    0.0%

That preserves the data, but the results are still ugly, and it also
requires some fancy footwork E<ndash> making the percentage sign part of
the field specification, as if it were L<a currency marker|
"Some tender money to me..."> E<ndash> to make the last field
work correctly. In other words: it's a kludge. The sad truth is that
sometimes variable-width fields are a better solution.

So C<form> provides them too. Any field specification may include a
plus sign (C<+>) anywhere between its braces, in which case it
specifies an I<extensible field>: a field whose width is minimal,
rather than absolute. So, in the above example, our call to C<form>
should actually look like this:

    for (@procs) {
        print form
            '{>>>}  {<<<<<<<(20)<<<<<<<}  {>>>>>+}  {>>.}%',
            $_->{pid}, $_->{cmd},        $_->{time},  $_->{cpu};
    }

and would produce this:

     2461  vi -ii henry           0:55.83   11.6%
     2395  ex cathedra            0:06.59    3.5%
    27384  lynx www.divorce.com  1214:23.75    0.8%
     2439  head anne.boleyn       0:00.18    0.1%
     2581  dig -short grave       0:01.04    0.0%

just like C<printf> does.

Likewise, if we thought the command names might exceed 20 columns we
could let that field stretch too:

    for (@procs) {
        print form
            '{>>>}  {<<<<<<<(20+)<<<<<<}  {>>>>>+}  {>>.}%',
            $_->{pid}, $_->{cmd},        $_->{time},  $_->{cpu};
    }

Note that the field width specifier would still warn us if the field's
"picture" was not exactly 20 columns wide, but the resulting field
would nevertheless stretch as necessary to accommodate longer data.


=head2 Whitespace squeezing

When a field is being filled in, whitespace is normally left as-is
(except for justification, and wrapping of lines in block fields).
However, this behaviour can be altered by specifying a I<whitespace
squeezing> strategy. Squeezing replaces those substrings of the data
that match a specified pattern (for example: C</\s+/>), substituting
a single space character.

If we don't want the default (non-)squeezing strategy we can use
the C<ws> option specify the particular pattern that is to be
used for squeezing:

    print form
        {ws=>qr/\h+/},           # squeeze any horizontal whitespace
        $format1, \@data1,
        {ws=>qr/$comment|\s+/},  # now squeeze comments or whitespace
        $format2, \@data2;

For example, suppose we have a eulogy generator:

    sub eulogize ($who, $to, $blaming) {...}

that (rather poorly) drops the appropriate names into a pre-formatted template,
to produce strings like:

    Friends,   Romans  , countrymen, lend me your ears;
    I come to bury    Caesar   , not to praise him.
    The evil that men do lives after them;
    The good is oft interred with their bones;
    So let it be with    Caesar    . The noble    Brutus
    Hath told you     Caesar     was ambitious:
    If it were so, it was a grievous fault,
    And grievously hath    Caesar    answer'd it.

If we interpolate that string, with its extra spaces and its embedded
newlines, into a C<form> field:

    print form
         '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
            eulogize('Caesar', 'Romans', 'Brutus');

we'd get:

    | Friends,   Romans  , countrymen, lend me   |
    | your ears;                                 |
    | I come to bury    Caesar   , not to praise |
    | him.                                       |
    | The evil that men do lives after them;     |
    | The good is oft interred with their bones; |
    | So let it be with    Caesar    . The noble |
    | Brutus                                     |
    | Hath told you     Caesar     was           |
    | ambitious:                                 |
    | If it were so, it was a grievous fault,    |
    | And grievously hath    Caesar    answer'd  |
    | it.                                        |

Note that the extra spaces and the embedded newlines
are preserved in the resulting text.

But, if we told C<form> to squeeze all whitespaces:

    print form {ws => qr/\s+/},
         '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
            eulogize('Caesar', 'Romans', 'Brutus');

we'd get:

    | Friends, Romans , countrymen, lend me your |
    | ears; I come to bury Caesar , not to       |
    | praise him. The evil that men do lives     |
    | after them; The good is oft interred with  |
    | their bones; So let it be with Caesar .    |
    | The noble Brutus Hath told you Caesar was  |
    | ambitious: If it were so, it was a         |
    | grievous fault, And grievously hath Caesar |
    | answer'd it.                               |

with each sequence of characters that match C</\s+/> being reduced
to a single space.

On the other hand, if we wanted to preserve the newlines and squeeze
only horizontal whitespace, that would be:

    print form {ws => qr/[ \t]+/},
         '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
            eulogize('Caesar', 'Romans', 'Brutus');

which produces:

    | Friends, Romans , countrymen, lend me your |
    | ears;                                      |
    | I come to bury Caesar , not to praise him. |
    | The evil that men do lives after them;     |
    | The good is oft interred with their bones; |
    | So let it be with Caesar . The noble       |
    | Brutus                                     |
    | Hath told you Caesar was ambitious:        |
    | If it were so, it was a grievous fault,    |
    | And grievously hath Caesar answer'd it.    |

Of course, for this particular text, none of these solutions is entirely
satisfactory since squeezing the whitespaces to a single space still leaves a
single space in places like C<"Caesar ."> and C<"Romans ,">.

To remove those blemishes we need to take advantage of a more
sophisticated aspect of C<form>'s whitespace squeezing behaviour. Namely
that, when squeezing whitespace using a particular pattern, C<form>
detects if that pattern captures anything and I<doesn't> squeeze the
captured items.

More precisely, if the squeeze pattern matches but doesn't capture,
C<form> simply replaces the entire match with a single space character.
But if the squeeze pattern I<does> capture, C<form> doesn't insert a
space character, but instead replaces the entire match with the
concatenation of the captured substrings.

That means we can completely eliminate any whitespace before a punctuation
character with:

    print form {ws => qr/[ \t]+ ([.!?,:;])?/},
         '| {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[} |',
            eulogize('Caesar', 'Romans', 'Brutus');

which produces the desired:

    | Friends, Romans, countrymen, lend me your  |
    | ears;                                      |
    | I come to bury Caesar, not to praise him.  |
    | The evil that men do lives after them;     |
    | The good is oft interred with their bones; |
    | So let it be with Caesar. The noble Brutus |
    | Hath told you Caesar was ambitious:        |
    | If it were so, it was a grievous fault,    |
    | And grievously hath Caesar answer'd it.    |

This works because, in those instances where the pattern
matches some whitespace followed by one of the
punctuation characters, the punctuation character is captured,
and the captured character is then used to replace the entire
whitespace-plus-punctuator. On the other hand, if the
pattern matches whitespace but no punctuator (and it's allowed to do that
because the punctuator is optional), then nothing is captured, so
C<form> falls back to replacing the whitespace with a single space.


=head2 Field filling

Fields are (almost) always of a fixed width. So, if there isn't
enough data to fill a particular field, the unused portions of that
field are filled in with spaces to preserve the vertical alignment of
other columns of formatted data. However, spaces are only the
default. The C<hfill> (horizontal fill) option can be used to change
fillers. For example:

    print form
        {hfill=>"=-"},                  # Fill next fields with "=-"
        '{|{*}|}',                      # Full width field for title
        '[ Table of Contents ]',        # Title
        {hfill=>" ."},                  # Fill next fields with spaced dots
        '   {[[[[[{*}[[[[[}{]]]}   ',   # Two indented block fields
            \@contents,    \@page;      # Data for those blocks

This fills the empty space either side of the centred title with a repeated
C<=-=-=-> sequence. It then fills the gaps to the right of the left-justified
the contents field, and to left of the right-justified pages field,
with spaced dots. Which, rather prettily, produces something like:

    =-=-=-=-=-=-=-[ Table of Contents ]-=-=-=-=-=-=-=

       Foreword. . . . . . . . . . . . . . . . . .i
       Preface . . . . . . . . . . . . . . . . .iii
       Glossary. . . . . . . . . . . . . . . . . vi
       Introduction. . . . . . . . . . . . . . . .1
       The Tempest . . . . . . . . . . . . . . . .7
       Two Gentlemen of Verona . . . . . . . . . 17
       The Merry Wives of Winsor . . . . . . . . 27
       Twelfh Night. . . . . . . . . . . . . . . 39
       Measure for Measure . . . . . . . . . . . 50
       Much Ado About Nothing. . . . . . . . . . 62
       A Midsummer Night's Dream . . . . . . . . 73
       Love's Labour's Lost. . . . . . . . . . . 82
       The Merchant of Venice. . . . . . . . . . 94
       As You Like It. . . . . . . . . . . . . .105

Note that the fill sequence doesn't have to be a single character and
that the fill pattern is consistent across multiple fields and between
adjacent lines. That is, it's as if every field is first filled with the
same fill pattern, then the actual data written over the top.
That's particularly handy in the above example, because it ensures that
the fill pattern seamlessly bridges the boundary between the adjacent
contents and pages fields.

It's also possible to specify separate fill sequences for the left-
and right-hand gaps in a particular field, using the C<lfill> and C<rfill>
options. This is particularly common for numerical fields. For example,
this call to C<form>:

    print form
      'Name              Bribe (per dastardry)',
      '=============     =====================',
      '{[[[[[[[[[[[}         {]],]]].[[[}     ',
      \@names,               \@bribes;

would print something like:

    Name              Bribe (per dastardry)
    =============     =====================
    Crookback                  12.676
    Iago                        1.62
    Borachio               45,615.0
    Shylock                    19.0003

with the numeric field padded with whitespace and
only showing as many decimal places as there are in
the data.

However, in order to prevent subsequent..err...creative calligraphy
(they I<are>, after all, villains and would presumably not hesitate
to add a few digits to the front of each number), we might prefer to
put stars before the numbers and show all decimal places.
We could do that like so:

    print form
      'Name              Bribe (per dastardry)',
      '=============     =====================',
      '{[[[[[[[[[[[}         {]],]]].[[[}     ',
      \@names,               {lfill=>'*', rfill=>'0'},
                             \@bribes;

which would then print:

    Name              Bribe (per dastardry)
    =============     =====================
    Crookback             *****12.6760
    Iago                  ******1.6200
    Borachio              *45,615.0000
    Shylock               *****19.0003

Note that the C<lfill> and C<rfill> options are specified I<after> the
format string and, more particularly, before the data for the second
field. This means that those options only take effect for that
particular field and the previous fill behaviour is then reasserted
for subsequent fields. Many other C<form> options E<ndash> for example C<ws>,
C<height>, or C<break> E<ndash> can be specified in this way, so as to
apply them only to a particular field.

There is also a general C<fill> option that sets the default
sequence for any filling that isn't otherwise specified.


=head2 Zero-filled numeric fields

Filling numeric fields with zeros is so common that C<form> offers a
shorthand notation for it. If the first character inside a numeric field specification is a zero, then the left-fill string for that field is set to C<"0">.
Likewise if the last character in the field is a zero, it is right-filled
with zeros. For example:

    my @nums = (0, 1, -1.2345, 1234.56, -1234.56, 1234567.89);

    print form
        '{]]]].[[}     {]]]].[0}     {0]]].[[}     {0]]].[0}',
         \@nums,       \@nums,       \@nums,       \@nums;

prints:

        0.0           0.000     00000.0       00000.000
        1.0           1.000     00001.0       00001.000
       -1.234        -1.234     -0001.234     -0001.234
     1234.56       1234.560     01234.56      01234.560
    -1234.56      -1234.560     -1234.56      -1234.560
    #####.###     #####.###     #####.###     #####.###



=head2 Up and down, up and down, I will lead them up and down...

Formatted text blocks are also filled vertically. Empty lines at the end
of the block are normally filled with spaces (so as to preserve the
alignment of any other fields on the same line). However, this too can
be controlled, with the C<vfill> option. Alternatively E<ndash> as with
horizontal filling E<ndash> separate fill sequences can be specified for
above and below the text using the C<tfill> and C<bfill> ("top" and
"bottom" fill) options.

For example, if we had six elements in C<@task>, but only four processors:

    print form
        {bfill=>'[unallocated]'},
        'Task                      Processor',
        '====                      =========',
        '{[[[[[[[[[[[[[[[[[[[[}  {]]]]]][[[[[}',
         \@task,                     [1..4];

we'd get:

    Task                      Processor
    ====                      =========
    Borrow story                  1
    Rename characters             2
    Subdivide into scenes         3
    Write dialogue                4
    Check rhythm and meter  [unallocated]
    Insert puns and japes   [unallocated]


=head2 Height control

It is possible to constrain the minimum and maximum number of lines
that a particular format or block field must cover, regardless of how much
data it contains. We do that using the C<height> option. For example:

    print form
        {height=>3},
        '{[[[[}{IIII}{]]]]}',
         $l,   $c,   $r;

This will cause the call to C<form> to generate exactly three output lines,
even if the contents of the data variables would normally fit in fewer lines
or would actually require more.

To specify a range of heights we can use the C<min> and C<max> suboptions:

    print form
        {height=>{ min=>3, max=>20 }},
        '{[[[[}{IIII}{]]]]}',
         $l,   $c,   $r;

This specifies that, no matter how much data is available, the output will be
no less than three lines and no more than 20.

Note, however, that the C<height> option refers to the height of individual
fields, not of entire output pages. we'll see how to control the
latter L<shortly|"Page dimensions">.


=head2 Minimal height fields

As we saw earlier, a block overflow field (C<{VVVVVVVVV}>)
has the special property that it only overflows as much as necessary to
fill the output lines generated by other block fields. That enabled us
to create an overflowing column of text like so:

    print form
        {interleave=>1}, <<EOFORMAT,
    Name:
      {[[[[[[[[[[[[}
                      Biography:
    Status:             {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}
      {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
                        {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
      {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    EOFORMAT
        $name,
        $biography,
        $status,
        $comments;

without the first C<{VVVVVVVVV}> field eating all the data out of C<$bio> and
leaving a large gap between the Status and the Comments.

That's a very handy feature, but restricting the "minimal height" feature
to overflow fields turns out to be not good enough in the general case.
For instance, suppose we had wanted the biography field to start at the
first line of the output text:

    Name:             Biography:
      William           William Shakespeare was born on
      Shakespeare       April 23, 1564 in Strathford-upon-
                        Avon, England; he was third of
    Status:             eight children from Father John
      Deceased (1564    Shakespeare and Mother Mary Arden.
      -1616)            Shakespeare began his education at
                        the age of seven when he probably
    Comments:           attended the Strathford grammar
      Theories          school. The school provided
      abound as to      Shakespeare with his formal
      the true          education. The students chiefly
      author of his     studied Latin rhetoric, logic, and
      plays. The        literature. His knowledge and
      prime             imagination may have come from his
      alternative       reading of ancient authors and
      candidates        poetry. In November 1582,
      being Sir         Shakespeare received a license to
      Francis           marry Anne Hathaway. At the time of
      Bacon,            their marriage, Shakespeare was 18
      Christopher       years old and Anne was 26. They had
      Marlowe, or       three children, the oldest Susanna,
      Edward de         and twins- a boy, Hamneth, and a
      Vere              girl, Judith. Before his death on
                        April 23 1616, William Shakespeare
                        had written thirty-seven plays. He
                        is generally considered the greatest
                        playwright the world has ever known
                        and has always been the world's most
                        popular author.

To do that, we would have required a call to C<form> like this:

    print form
        {interleave=>1}, <<EOFORMAT,
    Name:             Biography:
      {[[[[[[[[[[[[}    {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}
                        {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    Status:             {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
      {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
                        {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
      {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    EOFORMAT
        $name,
        $biography,
        $status,
        $comments;

Note that the first line of the Biography field now has to be a block field,
not a single-line field (as in previous versions). It can't be a single-line,
because the Name field is a block field and that would leave a gap in the
Biography column:

    Name:             Biography:
      William           William Shakespeare was born on
      Shakespeare
                        April 23, 1564 in Strathford-upon-
    Status:             Avon, England; he was third of
                        etc.

So it has to be a block field, to "keep up" with however much output the
multi-line Name field produces. Unfortunately, starting the Biography column
with a normal block field doesn't solve the problem either. In fact we get:

    Name:             Biography:
      William           William Shakespeare was born on
      Shakespeare       April 23, 1564 in Strathford-upon-
                        Avon, England; he was third of
                        eight children from Father John
                        Shakespeare and Mother Mary Arden.
                        Shakespeare began his education at
                        the age of seven when he probably
                        attended the Strathford grammar
                        school. The school provided
                        Shakespeare with his formal
                        education. The students chiefly
                        studied Latin rhetoric, logic, and
                        literature. His knowledge and
                        imagination may have come from his
                        reading of ancient authors and
                        poetry. In November 1582,
                        Shakespeare received a license to
                        marry Anne Hathaway. At the time of
                        their marriage, Shakespeare was 18
                        years old and Anne was 26. They had
                        three children, the oldest Susanna,
                        and twins- a boy, Hamneth, and a
                        girl, Judith. Before his death on
                        April 23 1616, William Shakespeare
                        had written thirty-seven plays. He
                        is generally considered the
                        greatest playwright the world has
                        ever known and has always been the
                        world's most popular author.

    Status:
      Deceased (1564
      -1616)

    Comments:
      Theories
      abound as to
      the true
      author of his
      plays. The
      prime
      alternative
      candidates
      being Sir
      Francis
      Bacon,
      Christopher
      Marlowe, or
      Edward de
      Vere

Normal block fields are remorseless in consuming all of their data.
So the first Biography field absolutely will not stop formatting, ever,
until your entire C<$biography> string is gone.

What we really need here, is a kinder, gentler block field; a
block field that formats minimally, like an overflow field.
And we get that with yet another C<height> option:
C<< height=>"minimal" >>. Like so:

    print form
        {interleave=>1}, <<EOFORMAT,
    Name:             Biography:
      {[[[[[[[[[[[[}    {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}
                        {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    Status:             {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
      {[[[[[[[[[[[[}    {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
                        {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    Comments:           {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
      {[[[[[[[[[[[}     {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}
    EOFORMAT
         $name,
         {height=>"minimal"}, $biography,
         $status,
         $comments;

When this option is applied to a particular field (by placing it
immediately before the field's data), that field only consumes
as much of its data is is required to fill the output lines created by
the other (non-minimal) fields in the same format. In this case, that means
that the first Biography field only extracts as much data from C<$biography>
as is needed to fill the text lines created by the Name field.

Note that any kind of block field can be modified in this way:
justified, numeric, currency, or verbatim.


=head2 Underlining

As some of the examples we've seen so far illustrate, formats frequently
consist of a set of column titles, followed by the corresponding columns
of data. And, typically, those column titles are underlined to make them
stand out:

    print form
      'Name              Bribe (per dastardry)',
      '=============     =====================',
      '{[[[[[[[[[[[}         {]],]]].[[[}     ',
      \@names,               \@bribes;

So C<form> has an option that automates that process. For
example, the payments example above could also have been written:

    print form
      'Name              Bribe (per dastardry)',
      {under=>"="},
      '{[[[[[[[[[[[}         {]],]]].[[[}     ',
      \@names,               \@bribes;

The C<under> option takes a string and uses it to underline the most
recently formatted line. It does this by examining the formats
immediately before and after the C<under>. It then generates a
series of underlines by repeating the specified underlining string
as many times as required. The underlines are generated such that
every field and every other non-whitespace literal in the preceding
format has a underline under it and every field/non-whitespace in
the next format has an "overline" above it.

For example, this call to C<form>:

    print form
        '      Rank Name         Serial Number',
        {under=>"_"},
        '{]]]]]]]]} {[[[[[[[[[}     {IIIII}',
            \@ranks,\@names,        \@nums;

prints:

          Rank Name         Serial Number
    __________ ___________  _____________
      Corporal Nym              CMXVII
    Lieutenant Bardolph          CCIV
       Captain Spurio           MMMCDX
       General Pompey             XI

The usual effect is that the auto-generated underlines always
extend to the edges of both the preceding title and the following
field, whichever is wider.

Many people, of course, prefer to draw the underlines themselves, as
the results are then much easier to visualize when looking at the code.
The C<under> option is most useful when we're constructing tables
programmatically, with columns and column titles that are only known
at run-time.


=head2 Output trimming

The default fill-with-spaces behaviour of fields is useful to preserve
the vertical alignment of columns within a formatted text, but it could
also potentially increase the size of C<form>'s output unnecessarily.
For example, the following:

    print form
        'To Do:',
        '   {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
            \@todo;

might produce something like:

    To Do:
       Dissemble
       Deceive
       Dispute
       Defy
       Duel
       Defeat
       Dispatch

That looks fine but, because each line is produced by the large
left-justified field that is automatically filled with whitespace, the
output contains several hundred more space characters than are strictly
necessary (you probably didn't notice them, but they're all there
E<ndash> hanging off the right sides of the individual To-Do items).

Fortunately, however, C<form> is smarter than that. Extraneous trailing
whitespace on the right-hand side of any output line is automatically
trimmed. So the above example actually produces:

    To Do:
       Dissemble
       Deceive
       Dispute
       Defy
       Duel
       Defeat
       Dispatch

Of course, if you really do need those "invisible" trailing whitespaces
for some reason, C<form> provides a way to keep them E<ndash> the
C<untrimmed> option:

    print form {untrimmed=>1},
        'To Do:',
        '   {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
            \@todo;


=head1 Page control

Normally, C<form> assumes that whatever data it is formatting is supposed
to produce a single, arbitrarily long, unbroken piece of text. But C<form>
can also format data into multiple pages of fixed length and width,
inserting customized, page-specific headers, footers, and pagefeeds
for each page.

All these features are controlled by the the C<page> option (or more
precisely, by its various suboptions):

    print form
        { page => { length => $page_len,        # Default: 60 lines
                    width  => $page_width,      # Default: 78 columns
                    number => $first_page_num,  # Default: 1
                    header => \&make_header,    # Default: no header
                    footer => \&make_footer,    # Default: no footer
                    feed   => \&make_pagefeed,  # Default: no pagefeed
                    body   => \&adjust_body,    # Default: no chiropracty
                  }
        },
        $format,
        \@data;


=head2 Measure his woe the length and breadth of mine...

The C<< page => { length => ... } >> suboption determines the number of output
lines per page (including headers and footers). Normally,
this suboption is set to infinity, which produces that single, arbitrarily
long, unbroken page of text. But the suboption can be set to any
positive integer value, to cause C<form> to generate distinct
pages of that many lines each.

Note however, that if the value specified for the page length results in
no formatted text appearing on a page (because the available length is
entirely consumed by headers or footers), then the length will be (silently)
increased so that a single line of content appears on each page.

The value of the C<< page => { width => ... } >> suboption is
used to determine the width of distributive fields and
in some L<page body postprocessors|"Page body postprocessing">.
By default, this suboption is set to 78 (columns), but it may
be set to any positive integer value.

The C<< page => { number => ... } >> suboption specifies the current page number.
By default it starts at 1, but may be set to any numeric value.
This suboption is generally only of use in headers and footers (see below).


=head2 Headers and footers

The C<< page => { header => ... } >> suboption specifies a hash containing
a set of strings or subroutines that are to be used to create page headers.
Each key of the hash indicates a particular kind of page that the
corresponding value will provide the header for. For example:

    header => { first => "           'The Tempest' by W. Shakespeare          ",
                last  => "                   -- The End --                    ",
                odd   => "Act $act, Scene $scene                              ",
                even  => "                                                    ",
                other => "          [Thys hedder intenshunally blanke]        ",
              }

Given the above specification, C<form> will:

=over

=item *

use the full title and author as the header of the first page,

=item *

write C<"-- The End --"> across the top of the last page,

=item *

prepend the act and scene information to the start of any odd page
(except, of course, the first or the last), and

=item *

provide an empty line as the header of any even page (except the last,
if it happens to be even).

=back

Note that, in this case, since we've provided specific headers for every
odd and even page, the C<"other"> header will never be used. On the other
hand, if we'd specified:

    header => { first => "           'The Tempest' by W. Shakespeare          ",
                other => "                                       'The Tempest'",
              }

then every page except the first would have just a right-justified title at
the top.

Of course, if we want every page to have the same header, we can just write:

    header => { other => "                                       'The Tempest'"}

But that's a little klunky, so C<form> also accepts a single string instead of
a hash, to specify a header to be used for every page:

    header  => "                                       'The Tempest'"

Headers don't all have to be the same size either. For example, we might
prefer a more imposing first header:

    header => { first => "                  'The Tempest'                   \n"
                       . "                        by                        \n"
                       . "                  W. Shakespeare                  \n"
                       . "____________________________________________________",

                other => "                                       'The Tempest'",
              }

C<form> simply notes the number of lines each header requires and then
reduces the available number of lines within the page accordingly,
so as to preserve the exact overall page length.

Often we'll need headers that aren't fixed strings. For example, we might
want each page to include the appropriate page number. So instead of a string,
we're allowed to specify a particular header as a subroutine. That subroutine
is then called each time that particular header is required, and its return
value is used as the required header.

When the subroutine is called, the current set of active formatting
options are passed to it as a list of pairs. Typically, then, the
subroutine will specify one or more named-only parameters corresponding
to the options it cares about, followed by a starred hash parameter to
collect the rest. For example if every page should have its
(left-justified) page number for a header:

    header => sub { return $_[0]{page}{number}; }

Footers work in exactly the same way in almost all respects; the obvious
exception being that they're placed at the end of a page, rather than the
start.

Pagefeeds work the same way too. A pagefeed is a string that is placed
between the footer of one page and the header of the next. They're like
formfeeds, except they can be any string we choose.
They're called "pagefeeds" instead of "formfeeds" because they're
placed between pages, not between calls to C<form>.



=head2 Page body postprocessing

Sometimes it's useful to be able to grab the entire body of a page
(i.e. the contents of the page between the header and footer)
I<after> it's been formatted together. For example, we might wish to
centre those contents, or to crop them at a particular column.

To this end, the C<< page => { body => ... } >> suboption allows us to specify
a page body post-processor. That is, a subroutine or format that
lays out the page's formatted text between the page's header and footer.
Like the C<header>, C<footer>, and C<feed> suboptions, the
C<body> suboption can take either a closure, a hash, or a string.

If the value of the C<body> suboption is a string or a hash of
pairs, the text of the body is (recursively) C<form>'ed using that
string (or those string values) as its format. A very common usage is to
arrange for the formatted text to be horizonally and vertically
centred on each page:

    body => '{=I{*}I=}'

A more sophisticated variation on this is to use a hash to insert a
left or right "gutter" for each page:

    $gutter = " " x $gutter_width;

    body => { odd   =>  $gutter ~ '{"""{*}"""}',
              even  =>  '{"""{*}"""}' ~ $gutter,
            }

On the other hand, if the value of the C<body> suboption is a subroutine,
the body text is passed to that sub as a reference to an array of lines. A
second array reference is also passed in, containing as many newlines as would
be needed to pad out the body text to the correct number of lines
for the page. Finally, the current formatting options are passed as
a hash reference. As with the C<header> etc. suboption, the closure
is expected to return a single string (representing the final
formatting of the page body).

For example, to add line numbers to the text each page (but I<not>
to the headers or footers or filler lines):

    my $linenum = 1;

    sub numerate {
        my @lines = @{$_[0]};
        my @fill  = @{$_[1]};
        my $page  = ${$_[2]}{page};

        # Compute range of line numbers
        my @linenums = ($linenum .. $linenum+@lines-1);

        # Reformat body lines verbatim,
        # with a left-justified line number before each...
        my $body = form '{[[[[} {"""{*}"""}',
                         \@linenums, \@lines,
                        @fill;

        # Update the final line number and return the new body text...
        $linenum += @lines;
        return $body;
    }

    print form
        page => { body   => \&numerate,
                  header => "\n==========\n\n",
                  length => 12,
                },
        # Left-justify the Briton...
        '{[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
        $soliloquy{RichardIII},
                         # Right-justify the Dane...
        '                 {]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]}',
                          $soliloquy{Hamlet};

which produces:

    ==========

    1      Now is the winter of our discontent /
    2      Made glorious summer by this sun of
    3      York; / And all the clouds that lour'd
    4      upon our house / In the deep bosom of
    5      the ocean buried. / Now are our brows
    6      bound with victorious wreaths; / Our
    7      bruised arms hung up for monuments; /
    8      Our stern alarums changed to merry
    9      meetings, / Our dreadful marches to

    ==========

    10     delightful measures. Grim-visaged war
    11     hath smooth'd his wrinkled front; / And
    12     now, instead of mounting barded steeds
    13     / To fright the souls of fearful
    14     adversaries, / He capers nimbly in a
    15     lady's chamber.




    ==========

    16                      To be, or not to be -- that is the question: /
    17                         Whether 'tis nobler in the mind to suffer /
    18                       The slings and arrows of outrageous fortune /
    19                         Or to take arms against a sea of troubles /
    20                       And by opposing end them. To die, to sleep --
    21                         / No more -- and by a sleep to say we end /
    22                      The heartache, and the thousand natural shocks
    23                      / That flesh is heir to. 'Tis a consummation /
    24                        Devoutly to be wished. To die, to sleep -- /

    ==========

    25                         To sleep -- perchance to dream: ay, there's
    26                          the rub, / For in that sleep of death what
    27                         dreams may come / When we have shuffled off
    28                             this mortal coil, / Must give us pause.
    29                        There's the respect / That makes calamity of
    30                                                       so long life.






                   E<nbsp>



=head1 User-defined fields

Perl6::Form provides a large variety of field types, but not every
possible type. For example, suppose we want a field that masks
its data in some way.  Perhaps a field that blanks out certain
words by replacing them with the corresponding number of X's.

We could always do that by writing a subroutine that generates the
appropriate filter:

    sub expurgate {
        my $hidewords = join "|", map quotemeta, @_;
        return sub {
            $_[0] =~ s/($hidewords)/ 'X' x length $1 /gixe;
            return $data;
        }
    }

We could then apply that subroutine to the data of any field that needed
bowdlerization:

    my $censor = expurgate qw(villain plot libel treacherous murderer false deadly 'G');

    print form
        "[Ye following tranfcript hath been cenfored by Order of ye King]\n\n",
        '         {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
                  $censor->($speech);

to produce:

    [Ye following tranfcript hath been cenfored by Order of ye King]

             And therefore, since I cannot prove a lover,
             To entertain these fair well-spoken days,
             I am determined to prove a XXXXXXX
             And hate the idle pleasures of these days.
             XXXXs have I laid, inductions dangerous,
             By drunken prophecies, XXXXXs and dreams,
             To set my brother Clarence and the king
             In XXXXXX hate the one against the other:
             And if King Edward be as true and just
             As I am subtle, XXXXX and XXXXXXXXXXX,
             This day should Clarence closely be mew'd up,
             About a prophecy, which says that XXX
             Of Edward's heirs the XXXXXXXX shall be.

Of course, if this were Puritanism and not Perl, we might have a long
list of proscribed words that we needed to excise from I<every> formatted text.
In that case, rather that explicitly running every data
source through the same censorious subroutine, it would be handy if C<form>
had a built-in field that did that for us automatically.

Naturally, C<form> doesn't have such a field built-in...but we
can certainly give it one.

User-defined field specifiers can be declared using the C<field> option,
which takes as its value an array of pairs. The key of each pair
is a string or a rule (i.e. regex) that specifies the syntax of the
user-defined field. The value of each pair is a closure/subroutine that
constructs a standard field specifier to replace the user-defined
specifier. Alternatively, the value of a pair may be a string, which is
taken as the (static) field specifier to be used instead of the
user-defined field.

In other words, each pair is a macro that maps a user-defined field
(specified by the pair's key) onto a standard C<form> field (specified by
the pair's value). For example:

    field => [ qr/\{ X+ \}/x => \&censor_field ]

This tells C<form> that whenever it finds a brace-delimited field consisting
of one or more X's, it should call a subroutine named C<censor_field> and
use the return value of that call instead of the all-X field.

When the key of a C<field> pair matches some part of a format,
its corresponding subroutine is called. That subroutine is passed
the Perl6ish result (i.e. C<$0>) of the regex
match, as well as a reference to the hash of active options for that field. Changes
to the options hash will affect the subsequent formatting behaviour of
that field.

So C<censor_field> could be implemented like so:

        # Constructor subroutine for user-defined censor fields...
        sub censor_field {
            my ($field_spec, $opts) = @_;

            # Set up the field's 'break' option with a censorious break...
            $opts->{break} = break_and_censor($->opts{break});

            # Construct a left-justified field with the appropriate width
            # specified imperatively...
            return '{[[{' . length($field_spec) . '}[[}';
        }

The C<censor_field> subroutine has to change the field's C<break>
option, creating a new line breaker that also expurgates unsuitable
words. To do this it calls C<break_and_censor>, which returns a new line
breaker subroutine:

        # Create a new 'break' sub...
        sub break_and_censor {
            my $original_breaker = @_;
            return sub {

                # Call the field's original 'break' sub...
                my ($nextline, $more) = $original_breaker->(@_);

                # X out any doubleplus ungood words
                $nextline =~ s/($proscribed_words)/ 'X' x length $1 /gixe;

                # Return the "corrected" version...
                return ($nextline, $more);
            }
        }

Having created a subroutine to translate censor fields and another to
break-and-expurgate the data placed in them, we are now in a position
to create a module that encapsulates the new formatting functionality:

    package Ministry::Of::Truth
    use Perl6::Export;

    # Internal mechanism (as above)...
    my $proscribed = "...";
    sub break_and_censor (&original_breaker) {...}
    sub censor_field ($field_spec, %opts) {...}

    # Make the new field type standard by default in this scope...
    use Form { field => [ rx/\{ X+ \}/ => \&censor_field ] };

    # Re-export the specialized &form that was imported above...
    sub form is export(:DEFAULT) {...}

}

Okay, admittedly that's quite a lot of work. But the pay-off is huge: we can now
trample on free speech I<much> more easily:

    use Ministry::Of::Truth;

    print form
        "[Ye following tranfcript hath been cenfored by Order of ye King]\n\n",
        '        {XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX}',
                  $speech;

And we'd get the same carefully XXXX'ed output as before.


=head2 Single-column fields

User-defined fields are also a handy way to create single-character
markers for single-column fields (in order to preserve the
one-to-one spacing of a format). For example:

    print form
        {field => { '^' => '{<III{1}III}',   # 1-char-wide, top-justified block
                    '=' => '{<=II{1}II=}',   # 1-char-wide, middle-justified block
                    '_' => '{<_II{1}II_}',   # 1-char-wide, bottom-justified block
                  }
        },
        '~~~~~~~~~',
        '^ _ = _ ^',   qw(like round and orient perls),
        '~~~~~~~~~';

prints:

    ~~~~~~~~~
    l     o p
    i r a r e
    k o n i r
    e u d e l
      n   n s
      d   t
    ~~~~~~~~~

Single fields are particularly useful for labelling the vertical axes of a
graph:

    use Perl6::Form {field => [ '=' => '{<=II{1}II=}' ] };

    $vert_label = "Success";
    $hor_label  = "Time";

    print form
       '   ^                                        ',
       ' = | {""""""""""""""""""""""""""""""""""""} ', $vert_label, \@data,
       '   +--------------------------------------->',
       '    {|||||||||||||||||||||||||||||||||||||} ', $hor_label;

which produces:

        ^
        |
        |       *
        |     *   *
      S |    *     *
      u |
      c |   *       *
      c |
      e |  *         *
      s |
      s |
        |
        | *           *
        +--------------------------------------->
                           Time

Specifying these kinds of single-character block markers is perhaps the
commonest use of user-defined fields. But the:

    field => [ '=' => '{<=II{1}II=}' ]

syntax is uncomfortably verbose for that purpose. So calls to
C<form> can also accept a short-hand notation to define a
single-character field:

    single => '='

or to define several at once:

    single => ['#', '*', '+']

The C<single> option does exactly the same thing as the C<field> options
shown above. It takes a single-character string, or a reference
to an array of such strings, as its value. It then turns each of those
strings into a single-column field marker. If the character is C<'='>
then the field is vertically "middled" within its block. If the
character is C<'_'> then the field is "bottomed" within its block. If
the single character is anything else, the resulting block is top-justified.
So our previous example could also have been written:

    print form
        {single => "="},
        '    ^                                        ',
        ' =  | {""""""""""""""""""""""""""""""""""""} ', $vert_label, \@data,
        '    +--------------------------------------->',
        '     {|||||||||||||||||||||||||||||||||||||} ', $hor_label;


=head1 Bulleted lists

Suppose we want a list of items bulleted by "diamonds":

    <> A rubber sword (laminated with mylar to
       look suitably shiny).
    <> Cotton tights (summer performances).
    <> Woolen tights (winter performances or
       those actors who are willing to admit
       to being over 65 years of age).
    <> Talcum powder.
    <> Codpieces (assorted sizes).
    <> Singlet.
    <> Double.
    <> Triplet (Kings and Emperors only).
    <> Supercilious attitude (optional).

Something like this works well enough:

    for my $item (@items) {
        print form
            '<> {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}', $item;
            '   {VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV}';
    }

The first format produces the bullet plus the first line of text for the item,
then the second format handles any overflow of the item data.

Alternatively, we could achieve the same result with a single format string
by interpolating the bullet as well:

    my $bullet = "<>";

    for my $item (@items) {
        print form
            q[{''{*}''} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}],
             $bullet,  $item;
    }

Here we use a single-line starred verbatim field (C<{''{*}''}>),
so that the bullet is interpolated "as-is" and the field
is only as wide as the bullet itself.
Then for the item itself we use a block field, which will format the item
data over as many lines as necessary. Meanwhile, because the bullet's
field is single-line, after the first line the bullet field will be
filled with spaces (instead of a "diamond"), leaving a bullet only on
the first line.

This second approach also has the advantage that we could change the bullet
string at run-time and the format would adapt automatically.

However, it's still a little irritating that we have to set up a loop and
call C<form> separately for each element of C<@items>. After all, if we
didn't need to bullet our list we could just write:

    print form
        '{[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
        \@items;

and C<form> would take care of iterating over the C<@items> for us. It
seems that things ought to be that easy for bulleted lists as well.

And, of course, things I<are> that easy.

All we need to do is tell C<form> that whenever the string C<< "<>" >>
appears in a format, it should be treated as a bullet. That is, it should
appear only beside the I<first> line of text produced when formatting each
element of the adjacent field's data.

To tell C<form> all that we use the C<bullet> option:

    print form
        {bullet => "<>"},
        '<> {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}',
            \@items;

The presence of this C<bullet> option causes C<form> to treat the sequence
C<< "<>" >> as a special field. That special field interpolates the
string C<< "<>" >> when the field immediately to its right begins to
format a new data element, but thereafter interpolates only spaces until
the adjacent field finishes formatting that data element.

Or, to put it more simply, if we tell C<form> that  C<< "<>" >> is a bullet,
C<form> treats it like a bullet that's attached to the very next field.

So we could allow our L<Shakespearean roles example|"Array data sources">
to handle multi-line character names, like so:

    print "The best Shakespearean roles are:\n\n";

    print form
        {bullet => "* "},
        '   * {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}   *{[[[[[[[[]]]]]]]]}*',
              \@roles,                                \$disclaimer;

This could then produce something like:

   The best Shakespearean roles are:

      * Either of the 'two foolish             *WARNING:          *
        officers': Dogberry and Verges         *This list of roles*
      * That dour Scot, the Laird              *constitutes      a*
        Macbeth                                *personal   opinion*
      * The tragic Moor of Venice,             *only and is in  no*
        Othello                                *way  endorsed   by*
      * Rosencrantz's good buddy               *Shakespeare'R'Us. *
        Guildenstern                           *It   may   contain*
      * The hideous and malevolent             *nuts.             *
        Richard III                            *                  *

Notice too that the asterisks on either side of the disclaimer I<aren't>
treated as bullets. That's because we defined a bullet to be C<"* ">, and
neither of the disclaimer asterisks has a space after it.

Bullets can be any string we like, and there can be more than one of them
in a single format. For example:

    print form
        {bullet => '+'},
        '+ {[[[[[[[[[[[[[[[[[[[:}       + {:[[[[[[[[[[[[[[[[[[[}',
            \@items,                      \@items;

would print:

    + A rubber sword,                65 years of age).
      laminated with mylar         + Talcum powder.
      to look suitably             + Codpieces (assorted
      shiny.                         sizes).
    + Cotton tights (summer        + Singlet.
      performances).               + Double.
    + Woolen tights (winter        + Triplet (Kings and
      performances or those          Emperors only).
      actors who are willing       + Supercilious attitude
      to admit to being over         (optional).


=head1 WARNING

The syntax and semantics of Perl 6 is still being finalized
and consequently is at any time subject to change. That means the
same caveat applies to this module.


=head1 DEPENDENCIES

Requires: Perl 5.8.0, Perl6::Export, Scalar::Util, List::Util.


=head1 AUTHOR

Damian Conway (damian@conway.org)


=head1 COPYRIGHT

 Copyright (c) 2003, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
    and/or modified under the same terms as Perl itself.
