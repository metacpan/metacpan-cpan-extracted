package Perinci::CmdLine::Gen;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.491'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Data::Dump qw(dump);
use File::Which;
use String::Indent qw(indent);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       gen_perinci_cmdline_script
                       gen_pericmd_script
               );

our %SPEC;

sub _pa {
    state $pa = do {
        require Perinci::Access;
        my $pa = Perinci::Access->new;
        $pa;
    };
    $pa;
}

sub _riap_request {
    my ($action, $url, $extras, $main_args) = @_;

    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0
        unless $main_args->{ssl_verify_hostname};

    _pa()->request($action => $url, %{$extras // {}});
}

$SPEC{gen_pericmd_script} = {
    v => 1.1,
    summary => 'Generate Perinci::CmdLine CLI script',
    args => {

        output_file => {
            summary => 'Path to output file',
            schema => ['filename*'],
            default => '-',
            cmdline_aliases => { o=>{} },
            tags => ['category:output'],
        },
        overwrite => {
            schema => [bool => default => 0],
            summary => 'Whether to overwrite output if previously exists',
            tags => ['category:output'],
        },

        url => {
            summary => 'URL to function (or package, if you have subcommands)',
            schema => 'riap::url*',
            req => 1,
            pos => 0,
        },
        subcommands => {
            'x.name.is_plural' => 1,
            summary => 'Hash of subcommand entries, where each entry is "url[:summary]"',
            'summary.alt.plurality.singular' => 'Subcommand name with function URL and optional summary',
            schema => ['hash*', of=>'str*'],
            description => <<'_',

An optional summary can follow the URL, e.g.:

    URL[:SUMMARY]

Example (on CLI):

    --subcommand add=/My/App/add_item --subcommand bin='/My/App/bin_item:Delete an item'

_
            cmdline_aliases => { s=>{} },
        },
        subcommands_from_package_functions => {
            summary => "Form subcommands from functions under package's URL",
            schema => ['bool', is=>1],
            description => <<'_',

This is an alternative to the `subcommands` option. Instead of specifying each
subcommand's name and URL, you can also specify that subcommand names are from
functions under the package URL in `url`. So for example if `url` is `/My/App/`,
hen all functions under `/My/App` are listed first. If the functions are:

    foo
    bar
    baz_qux

then the subcommands become:

    foo => /My/App/foo
    bar => /My/App/bar
    "baz-qux" => /My/App/baz_qux

_
        },
        default_subcommand => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => 'str*',
        },
        include_package_functions_match => {
            schema => 're*',
            summary => 'Only include package functions matching this pattern',
            links => [
                'subcommands_from_package_functions',
                'exclude_package_functions_match',
            ],
        },
        exclude_package_functions_match => {
            schema => 're*',
            summary => 'Exclude package functions matching this pattern',
            links => [
                'subcommands_from_package_functions',
                'include_package_functions_match',
            ],
        },
        cmdline => {
            summary => 'Specify module to use',
            schema  => 'perl::modname*',
            default => 'Perinci::CmdLine::Any',
            completion => ['classic', 'inline', 'lite'],
            cmdline_aliases => {
                classic => { code=>sub{ $_[0]{cmdline} = 'classic' }, is_flag=>1, summary => 'Shortcut for --cmdline=classic' },
                inline  => { code=>sub{ $_[0]{cmdline} = 'inline'  }, is_flag=>1, summary => 'Shortcut for --cmdline=inline'  },
                lite    => { code=>sub{ $_[0]{cmdline} = 'lite'    }, is_flag=>1, summary => 'Shortcut for --cmdline=lite'    },
            },
        },
        prefer_lite => {
            summary => 'Prefer Perinci::CmdLine::Lite backend',
            'summary.alt.bool.not' => 'Prefer Perinci::CmdLine::Classic backend',
            schema  => 'bool',
            default => 1,
        },
        pass_cmdline_object => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            description => <<'_',

Currently irrelevant when generating with Perinci::CmdLine::Inline.

_
            schema  => 'bool',
        },
        pack_deps => {
            summary => 'Whether to pack dependencies in Perinci::CmdLine::Inline script',
            schema => 'bool*',
            description => <<'_',

Will be passed to <pm:Perinci::CmdLine>'s `gen_inline_pericmd_script`'s
`pack_deps` option.

_
            tags => ['variant:inline'],
        },
        log => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema  => 'bool',
        },
        extra_urls_for_version => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => ['array*', of=>'str*'],
        },
        default_log_level => {
            schema  => ['str', in=>[qw/trace debug info warn error fatal none/]],
        },
        ssl_verify_hostname => {
            summary => q[If set to 0, will add: $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;' to code],
            schema  => 'bool',
            default => 1,
        },
        code_before_instantiate_cmdline => {
            schema => 'str',
        },
        code_after_end => {
            schema => 'str',
        },
        read_config => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => 'bool',
        },
        config_filename => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => ['any*', of=>[
                'str*',
                'hash*',
                ['array*', of=>['any*', of=>['str*','hash*']]],
            ]],
        },
        config_dirs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'config_dir',
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => ['array*', of=>'str*'],
        },
        read_env => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => 'bool',
        },
        env_name => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => 'str',
        },
        load_module => {
            summary => 'Load extra modules',
            schema => ['array', of=>'perl::modname*'],
        },
        allow_prereq => {
            summary => 'Allow script to depend on these modules',
            schema => ['array*', of=>'perl::modname*'],
            description => <<'_',

Sometimes, as in the case of using `Perinci::CmdLine::Inline`, dependency to
some modules (e.g. non-core XS modules) are prohibited because the goal is to
have a free-standing script. This option allows whitelisting some extra modules.

If you use `Perinci::CmdLine::Inline`, this option will be passed to it.

_
            tags => ['variant:inline'],
        },
        interpreter_path => {
            summary => 'What to put on shebang line',
            schema => 'str',
        },
        script_name => {
            schema => 'str',
        },
        script_summary => {
            schema => 'str',
        },
        script_version => {
            summary => 'Use this for version number instead',
            schema => 'str',
        },
        default_format => {
            summary => 'Set default format',
            schema  => 'str',
        },
        skip_format => {
            summary => 'Assume that function returns raw text which needs no formatting',
            schema  => 'bool',
        },
        use_cleanser => {
            summary => 'Whether to use data cleansing before outputting to JSON',
            schema  => 'bool',
        },
        use_utf8 => {
            summary => 'Whether to set utf8 flag on output, will be passed to Perinci::CmdLine constructor',
            schema  => 'bool',
        },
        default_dry_run => {
            summary => 'Whether to set default_dry_run, will be passed to Perinci::CmdLine constructor',
            schema  => 'bool',
        },
        per_arg_json => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => ['bool*'],
        },
        per_arg_yaml => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => ['bool*'],
        },
        validate_args => {
            summary => 'Will be passed to Perinci::CmdLine constructor',
            schema => ['bool*'],
        },

        pod => {
            summary => 'Whether to generate POD or not',
            schema => ['bool*'],
            description => <<'_',

Currently only Perinci::CmdLine::Inline generates POD.

_
            default => 1,
        },

        copt_version_enable => {
            schema => 'bool*',
            default => 1,
        },
        copt_version_getopt => {
            schema => 'str*',
        },
        copt_help_enable => {
            schema => 'bool*',
            default => 1,
        },
        copt_help_getopt => {
            schema => 'str*',
        },
    },
};
use experimental 'smartmatch'; no warnings ('void'); require List::Util; use experimental ("smartmatch"); require Scalar::Util; require URI; $SPEC{gen_pericmd_script} = {args=>{allow_prereq=>{description=>"\nSometimes, as in the case of using `Perinci::CmdLine::Inline`, dependency to\nsome modules (e.g. non-core XS modules) are prohibited because the goal is to\nhave a free-standing script. This option allows whitelisting some extra modules.\n\nIf you use `Perinci::CmdLine::Inline`, this option will be passed to it.\n\n", schema=>["array", {of=>"perl::modname*", req=>1}, {}], summary=>"Allow script to depend on these modules", tags=>["variant:inline"]}, cmdline=>{cmdline_aliases=>{classic=>{code=>$SPEC{gen_pericmd_script}->{args}{cmdline}{cmdline_aliases}{classic}{code}, is_flag=>1, summary=>"Shortcut for --cmdline=classic"}, inline=>{code=>$SPEC{gen_pericmd_script}->{args}{cmdline}{cmdline_aliases}{inline}{code}, is_flag=>1, summary=>"Shortcut for --cmdline=inline"}, lite=>{code=>$SPEC{gen_pericmd_script}->{args}{cmdline}{cmdline_aliases}{lite}{code}, is_flag=>1, summary=>"Shortcut for --cmdline=lite"}}, completion=>["classic", "inline", "lite"], default=>"Perinci::CmdLine::Any", schema=>["perl::modname", {req=>1}, {}], summary=>"Specify module to use"}, code_after_end=>{schema=>["str", {}, {}]}, code_before_instantiate_cmdline=>{schema=>["str", {}, {}]}, config_dirs=>{schema=>["array", {of=>"str*", req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor", "x.name.is_plural"=>1, "x.name.singular"=>"config_dir"}, config_filename=>{schema=>["any", {of=>["str*", "hash*", ["array*", "of", ["any*", "of", ["str*", "hash*"]]]], req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, copt_help_enable=>{default=>1, schema=>["bool", {req=>1}, {}]}, copt_help_getopt=>{schema=>["str", {req=>1}, {}]}, copt_version_enable=>{default=>1, schema=>["bool", {req=>1}, {}]}, copt_version_getopt=>{schema=>["str", {req=>1}, {}]}, default_dry_run=>{schema=>["bool", {}, {}], summary=>"Whether to set default_dry_run, will be passed to Perinci::CmdLine constructor"}, default_format=>{schema=>["str", {}, {}], summary=>"Set default format"}, default_log_level=>{schema=>["str", {in=>["trace", "debug", "info", "warn", "error", "fatal", "none"]}, {}]}, default_subcommand=>{schema=>["str", {req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, env_name=>{schema=>["str", {}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, exclude_package_functions_match=>{links=>["subcommands_from_package_functions", "include_package_functions_match"], schema=>["re", {req=>1}, {}], summary=>"Exclude package functions matching this pattern"}, extra_urls_for_version=>{schema=>["array", {of=>"str*", req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, include_package_functions_match=>{links=>["subcommands_from_package_functions", "exclude_package_functions_match"], schema=>["re", {req=>1}, {}], summary=>"Only include package functions matching this pattern"}, interpreter_path=>{schema=>["str", {}, {}], summary=>"What to put on shebang line"}, load_module=>{schema=>["array", {of=>"perl::modname*"}, {}], summary=>"Load extra modules"}, log=>{schema=>["bool", {}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, output_file=>{cmdline_aliases=>{o=>{}}, default=>"-", schema=>["filename", {req=>1}, {}], summary=>"Path to output file", tags=>["category:output"]}, overwrite=>{schema=>["bool", {default=>0}, {}], summary=>"Whether to overwrite output if previously exists", tags=>["category:output"]}, pack_deps=>{description=>"\nWill be passed to <pm:Perinci::CmdLine>'s `gen_inline_pericmd_script`'s\n`pack_deps` option.\n\n", schema=>["bool", {req=>1}, {}], summary=>"Whether to pack dependencies in Perinci::CmdLine::Inline script", tags=>["variant:inline"]}, pass_cmdline_object=>{description=>"\nCurrently irrelevant when generating with Perinci::CmdLine::Inline.\n\n", schema=>["bool", {}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, per_arg_json=>{schema=>["bool", {req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, per_arg_yaml=>{schema=>["bool", {req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, pod=>{default=>1, description=>"\nCurrently only Perinci::CmdLine::Inline generates POD.\n\n", schema=>["bool", {req=>1}, {}], summary=>"Whether to generate POD or not"}, prefer_lite=>{default=>1, schema=>["bool", {}, {}], summary=>"Prefer Perinci::CmdLine::Lite backend", "summary.alt.bool.not"=>"Prefer Perinci::CmdLine::Classic backend"}, read_config=>{schema=>["bool", {}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, read_env=>{schema=>["bool", {}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}, script_name=>{schema=>["str", {}, {}]}, script_summary=>{schema=>["str", {}, {}]}, script_version=>{schema=>["str", {}, {}], summary=>"Use this for version number instead"}, skip_format=>{schema=>["bool", {}, {}], summary=>"Assume that function returns raw text which needs no formatting"}, ssl_verify_hostname=>{default=>1, schema=>["bool", {}, {}], summary=>"If set to 0, will add: \$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;' to code"}, subcommands=>{cmdline_aliases=>{s=>{}}, description=>"\nAn optional summary can follow the URL, e.g.:\n\n    URL[:SUMMARY]\n\nExample (on CLI):\n\n    --subcommand add=/My/App/add_item --subcommand bin='/My/App/bin_item:Delete an item'\n\n", schema=>["hash", {of=>"str*", req=>1}, {}], summary=>"Hash of subcommand entries, where each entry is \"url[:summary]\"", "summary.alt.plurality.singular"=>"Subcommand name with function URL and optional summary", "x.name.is_plural"=>1}, subcommands_from_package_functions=>{description=>"\nThis is an alternative to the `subcommands` option. Instead of specifying each\nsubcommand's name and URL, you can also specify that subcommand names are from\nfunctions under the package URL in `url`. So for example if `url` is `/My/App/`,\nhen all functions under `/My/App` are listed first. If the functions are:\n\n    foo\n    bar\n    baz_qux\n\nthen the subcommands become:\n\n    foo => /My/App/foo\n    bar => /My/App/bar\n    \"baz-qux\" => /My/App/baz_qux\n\n", schema=>["bool", {is=>1}, {}], summary=>"Form subcommands from functions under package's URL"}, url=>{pos=>0, req=>1, schema=>["riap::url", {req=>1}, {}], summary=>"URL to function (or package, if you have subcommands)"}, use_cleanser=>{schema=>["bool", {}, {}], summary=>"Whether to use data cleansing before outputting to JSON"}, use_utf8=>{schema=>["bool", {}, {}], summary=>"Whether to set utf8 flag on output, will be passed to Perinci::CmdLine constructor"}, validate_args=>{schema=>["bool", {req=>1}, {}], summary=>"Will be passed to Perinci::CmdLine constructor"}}, args_as=>"hash", summary=>"Generate Perinci::CmdLine CLI script", v=>1.1, "x.perinci.sub.wrapper.logs"=>[{normalize_schema=>1, validate_args=>1, validate_result=>1}]}; sub gen_pericmd_script { ## this line is put by Dist::Zilla::Plugin::Rinci::Wrap
    my %args = @_; my $_sahv_dpath = []; my $_w_res = undef; for (sort keys %args) { if (!/\A(-?)\w+(\.\w+)*\z/o) { return [400, "Invalid argument name (please use letters/numbers/underscores only)'$_'"]; } if (!($1 || $_ ~~ ["allow_prereq","cmdline","code_after_end","code_before_instantiate_cmdline","config_dirs","config_filename","copt_help_enable","copt_help_getopt","copt_version_enable","copt_version_getopt","default_dry_run","default_format","default_log_level","default_subcommand","env_name","exclude_package_functions_match","extra_urls_for_version","include_package_functions_match","interpreter_path","load_module","log","output_file","overwrite","pack_deps","pass_cmdline_object","per_arg_json","per_arg_yaml","pod","prefer_lite","read_config","read_env","script_name","script_summary","script_version","skip_format","ssl_verify_hostname","subcommands","subcommands_from_package_functions","url","use_cleanser","use_utf8","validate_args"])) { return [400, "Unknown argument '$_'"]; } } if (exists($args{'allow_prereq'})) { my $err_allow_prereq; ((defined($args{'allow_prereq'})) ? 1 : (($err_allow_prereq //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'allow_prereq'}) eq 'ARRAY') ? 1 : (($err_allow_prereq //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type array"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'allow_prereq'}->[$_])) ? 1 : (($err_allow_prereq //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && (($args{'allow_prereq'}->[$_] = (1) ? (do { my $tmp = $args{'allow_prereq'}->[$_]; $tmp = $1 if $tmp =~ m!\A(\w+(?:/\w+)*).pm\z!; $tmp =~ s!::?|/|\.|-!::!g; $tmp }) : $args{'allow_prereq'}->[$_]), 1) && ((!ref($args{'allow_prereq'}->[$_])) ? 1 : (($err_allow_prereq //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) && (($args{'allow_prereq'}->[$_] =~ qr((?:(?-)\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z))) ? 1 : (($err_allow_prereq //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z"),0)) )}, 0..@{$args{'allow_prereq'}}-1))) ? 1 : (($err_allow_prereq //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Does not satisfy the following schema: each array element must be: (text, must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z)"),0)), pop(@{$_sahv_dpath})]->[1]); if ($err_allow_prereq) { return [400, "Argument 'allow_prereq' fails validation: $err_allow_prereq"]; } }  if (exists($args{'cmdline'})) { my $err_cmdline; ((defined($args{'cmdline'})) ? 1 : (($err_cmdline //= "Required but not specified"),0)) && (($args{'cmdline'} = (1) ? (do { my $tmp = $args{'cmdline'}; $tmp = $1 if $tmp =~ m!\A(\w+(?:/\w+)*).pm\z!; $tmp =~ s!::?|/|\.|-!::!g; $tmp }) : $args{'cmdline'}), 1) && ((!ref($args{'cmdline'})) ? 1 : (($err_cmdline //= "Not of type text"),0)) && (($args{'cmdline'} =~ qr((?:(?-)\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z))) ? 1 : (($err_cmdline //= "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z"),0)); if ($err_cmdline) { return [400, "Argument 'cmdline' fails validation: $err_cmdline"]; } } else { $args{'cmdline'} //= "Perinci::CmdLine::Any"; }  if (exists($args{'code_after_end'})) { my $err_code_after_end; (!defined($args{'code_after_end'}) ? 1 :  ((!ref($args{'code_after_end'})) ? 1 : (($err_code_after_end //= "Not of type text"),0))); if ($err_code_after_end) { return [400, "Argument 'code_after_end' fails validation: $err_code_after_end"]; } }  if (exists($args{'code_before_instantiate_cmdline'})) { my $err_code_before_instantiate_cmdline; (!defined($args{'code_before_instantiate_cmdline'}) ? 1 :  ((!ref($args{'code_before_instantiate_cmdline'})) ? 1 : (($err_code_before_instantiate_cmdline //= "Not of type text"),0))); if ($err_code_before_instantiate_cmdline) { return [400, "Argument 'code_before_instantiate_cmdline' fails validation: $err_code_before_instantiate_cmdline"]; } }  if (exists($args{'config_dirs'})) { my $err_config_dirs; ((defined($args{'config_dirs'})) ? 1 : (($err_config_dirs //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'config_dirs'}) eq 'ARRAY') ? 1 : (($err_config_dirs //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type array"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'config_dirs'}->[$_])) ? 1 : (($err_config_dirs //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((!ref($args{'config_dirs'}->[$_])) ? 1 : (($err_config_dirs //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) )}, 0..@{$args{'config_dirs'}}-1))) ? 1 : (($err_config_dirs //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)), pop(@{$_sahv_dpath})]->[1]); if ($err_config_dirs) { return [400, "Argument 'config_dirs' fails validation: $err_config_dirs"]; } }  if (exists($args{'config_filename'})) { my $err_config_filename; ((defined($args{'config_filename'})) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((1) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type any"),0)) && (((do { my $_sahv_ok = 0; my $_sahv_nok = 0; (        ((defined($args{'config_filename'})) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((!ref($args{'config_filename'})) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) ? ++$_sahv_ok : ++$_sahv_nok) && (        ((defined($args{'config_filename'})) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'config_filename'}) eq 'HASH') ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type hash"),0)) ? ++$_sahv_ok : ++$_sahv_nok) && (        ((defined($args{'config_filename'})) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'config_filename'}) eq 'ARRAY') ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type array"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'config_filename'}->[$_])) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((1) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type any"),0)) && (((do { my $_sahv_ok = 0; my $_sahv_nok = 0; (        ((defined($args{'config_filename'}->[$_])) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((!ref($args{'config_filename'}->[$_])) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) ? ++$_sahv_ok : ++$_sahv_nok) && (        ((defined($args{'config_filename'}->[$_])) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'config_filename'}->[$_]) eq 'HASH') ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type hash"),0)) ? ++$_sahv_ok : ++$_sahv_nok) && $_sahv_ok >= 1 && ($err_config_filename = undef, 1)}) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type must be either text or hash"),0)) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type must be either text or hash"),0)) )}, 0..@{$args{'config_filename'}}-1))) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type each array element must be: must be either text or hash"),0)), pop(@{$_sahv_dpath})]->[1]) ? ++$_sahv_ok : ++$_sahv_nok) && $_sahv_ok >= 1 && ($err_config_filename = undef, 1)}) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Does not satisfy the following schema: must be one of the following: text, hash, (array, each array element must be: must be either text or hash)"),0)) ? 1 : (($err_config_filename //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Does not satisfy the following schema: must be one of the following: text, hash, (array, each array element must be: must be either text or hash)"),0)); if ($err_config_filename) { return [400, "Argument 'config_filename' fails validation: $err_config_filename"]; } }  if (exists($args{'copt_help_enable'})) { my $err_copt_help_enable; ((defined($args{'copt_help_enable'})) ? 1 : (($err_copt_help_enable //= "Required but not specified"),0)) && ((!ref($args{'copt_help_enable'})) ? 1 : (($err_copt_help_enable //= "Not of type boolean value"),0)); if ($err_copt_help_enable) { return [400, "Argument 'copt_help_enable' fails validation: $err_copt_help_enable"]; } } else { $args{'copt_help_enable'} //= 1; }  if (exists($args{'copt_help_getopt'})) { my $err_copt_help_getopt; ((defined($args{'copt_help_getopt'})) ? 1 : (($err_copt_help_getopt //= "Required but not specified"),0)) && ((!ref($args{'copt_help_getopt'})) ? 1 : (($err_copt_help_getopt //= "Not of type text"),0)); if ($err_copt_help_getopt) { return [400, "Argument 'copt_help_getopt' fails validation: $err_copt_help_getopt"]; } }  if (exists($args{'copt_version_enable'})) { my $err_copt_version_enable; ((defined($args{'copt_version_enable'})) ? 1 : (($err_copt_version_enable //= "Required but not specified"),0)) && ((!ref($args{'copt_version_enable'})) ? 1 : (($err_copt_version_enable //= "Not of type boolean value"),0)); if ($err_copt_version_enable) { return [400, "Argument 'copt_version_enable' fails validation: $err_copt_version_enable"]; } } else { $args{'copt_version_enable'} //= 1; }  if (exists($args{'copt_version_getopt'})) { my $err_copt_version_getopt; ((defined($args{'copt_version_getopt'})) ? 1 : (($err_copt_version_getopt //= "Required but not specified"),0)) && ((!ref($args{'copt_version_getopt'})) ? 1 : (($err_copt_version_getopt //= "Not of type text"),0)); if ($err_copt_version_getopt) { return [400, "Argument 'copt_version_getopt' fails validation: $err_copt_version_getopt"]; } }  if (exists($args{'default_dry_run'})) { my $err_default_dry_run; (!defined($args{'default_dry_run'}) ? 1 :  ((!ref($args{'default_dry_run'})) ? 1 : (($err_default_dry_run //= "Not of type boolean value"),0))); if ($err_default_dry_run) { return [400, "Argument 'default_dry_run' fails validation: $err_default_dry_run"]; } }  if (exists($args{'default_format'})) { my $err_default_format; (!defined($args{'default_format'}) ? 1 :  ((!ref($args{'default_format'})) ? 1 : (($err_default_format //= "Not of type text"),0))); if ($err_default_format) { return [400, "Argument 'default_format' fails validation: $err_default_format"]; } }  if (exists($args{'default_log_level'})) { my $err_default_log_level; (!defined($args{'default_log_level'}) ? 1 :  ((!ref($args{'default_log_level'})) ? 1 : (($err_default_log_level //= "Not of type text"),0)) && (($args{'default_log_level'} ~~ ["trace","debug","info","warn","error","fatal","none"]) ? 1 : (($err_default_log_level //= "Must be one of [\"trace\",\"debug\",\"info\",\"warn\",\"error\",\"fatal\",\"none\"]"),0))); if ($err_default_log_level) { return [400, "Argument 'default_log_level' fails validation: $err_default_log_level"]; } }  if (exists($args{'default_subcommand'})) { my $err_default_subcommand; ((defined($args{'default_subcommand'})) ? 1 : (($err_default_subcommand //= "Required but not specified"),0)) && ((!ref($args{'default_subcommand'})) ? 1 : (($err_default_subcommand //= "Not of type text"),0)); if ($err_default_subcommand) { return [400, "Argument 'default_subcommand' fails validation: $err_default_subcommand"]; } }  if (exists($args{'env_name'})) { my $err_env_name; (!defined($args{'env_name'}) ? 1 :  ((!ref($args{'env_name'})) ? 1 : (($err_env_name //= "Not of type text"),0))); if ($err_env_name) { return [400, "Argument 'env_name' fails validation: $err_env_name"]; } }  if (exists($args{'exclude_package_functions_match'})) { my $err_exclude_package_functions_match; ((defined($args{'exclude_package_functions_match'})) ? 1 : (($err_exclude_package_functions_match //= "Required but not specified"),0)) && ((ref($args{'exclude_package_functions_match'}) eq 'Regexp' || !ref($args{'exclude_package_functions_match'}) && eval { my $tmp = $args{'exclude_package_functions_match'}; qr/$tmp/; 1 }) ? 1 : (($err_exclude_package_functions_match //= "Not of type regex pattern"),0)); if ($err_exclude_package_functions_match) { return [400, "Argument 'exclude_package_functions_match' fails validation: $err_exclude_package_functions_match"]; } }  if (exists($args{'extra_urls_for_version'})) { my $err_extra_urls_for_version; ((defined($args{'extra_urls_for_version'})) ? 1 : (($err_extra_urls_for_version //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'extra_urls_for_version'}) eq 'ARRAY') ? 1 : (($err_extra_urls_for_version //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type array"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'extra_urls_for_version'}->[$_])) ? 1 : (($err_extra_urls_for_version //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((!ref($args{'extra_urls_for_version'}->[$_])) ? 1 : (($err_extra_urls_for_version //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) )}, 0..@{$args{'extra_urls_for_version'}}-1))) ? 1 : (($err_extra_urls_for_version //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)), pop(@{$_sahv_dpath})]->[1]); if ($err_extra_urls_for_version) { return [400, "Argument 'extra_urls_for_version' fails validation: $err_extra_urls_for_version"]; } }  if (exists($args{'include_package_functions_match'})) { my $err_include_package_functions_match; ((defined($args{'include_package_functions_match'})) ? 1 : (($err_include_package_functions_match //= "Required but not specified"),0)) && ((ref($args{'include_package_functions_match'}) eq 'Regexp' || !ref($args{'include_package_functions_match'}) && eval { my $tmp = $args{'include_package_functions_match'}; qr/$tmp/; 1 }) ? 1 : (($err_include_package_functions_match //= "Not of type regex pattern"),0)); if ($err_include_package_functions_match) { return [400, "Argument 'include_package_functions_match' fails validation: $err_include_package_functions_match"]; } }  if (exists($args{'interpreter_path'})) { my $err_interpreter_path; (!defined($args{'interpreter_path'}) ? 1 :  ((!ref($args{'interpreter_path'})) ? 1 : (($err_interpreter_path //= "Not of type text"),0))); if ($err_interpreter_path) { return [400, "Argument 'interpreter_path' fails validation: $err_interpreter_path"]; } }  if (exists($args{'load_module'})) { my $err_load_module; (!defined($args{'load_module'}) ? 1 :  ((ref($args{'load_module'}) eq 'ARRAY') ? 1 : (($err_load_module //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type array"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'load_module'}->[$_])) ? 1 : (($err_load_module //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && (($args{'load_module'}->[$_] = (1) ? (do { my $tmp = $args{'load_module'}->[$_]; $tmp = $1 if $tmp =~ m!\A(\w+(?:/\w+)*).pm\z!; $tmp =~ s!::?|/|\.|-!::!g; $tmp }) : $args{'load_module'}->[$_]), 1) && ((!ref($args{'load_module'}->[$_])) ? 1 : (($err_load_module //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) && (($args{'load_module'}->[$_] =~ qr((?:(?-)\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\z))) ? 1 : (($err_load_module //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z"),0)) )}, 0..@{$args{'load_module'}}-1))) ? 1 : (($err_load_module //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Does not satisfy the following schema: each array element must be: (text, must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*\\z)"),0)), pop(@{$_sahv_dpath})]->[1])); if ($err_load_module) { return [400, "Argument 'load_module' fails validation: $err_load_module"]; } }  if (exists($args{'log'})) { my $err_log; (!defined($args{'log'}) ? 1 :  ((!ref($args{'log'})) ? 1 : (($err_log //= "Not of type boolean value"),0))); if ($err_log) { return [400, "Argument 'log' fails validation: $err_log"]; } }  if (exists($args{'output_file'})) { my $err_output_file; ((defined($args{'output_file'})) ? 1 : (($err_output_file //= "Required but not specified"),0)) && (($args{'output_file'} = (1) ? (do { (my $tmp = $args{'output_file'}) =~ s!/\z!!g; $tmp }) : $args{'output_file'}), 1) && ((!ref($args{'output_file'})) ? 1 : (($err_output_file //= "Not of type text"),0)); if ($err_output_file) { return [400, "Argument 'output_file' fails validation: $err_output_file"]; } } else { $args{'output_file'} //= "-"; }  if (exists($args{'overwrite'})) { my $err_overwrite; (($args{'overwrite'} //= 0), 1) && (!defined($args{'overwrite'}) ? 1 :  ((!ref($args{'overwrite'})) ? 1 : (($err_overwrite //= "Not of type boolean value"),0))); if ($err_overwrite) { return [400, "Argument 'overwrite' fails validation: $err_overwrite"]; } } else { $args{'overwrite'} //= 0; }  if (exists($args{'pack_deps'})) { my $err_pack_deps; ((defined($args{'pack_deps'})) ? 1 : (($err_pack_deps //= "Required but not specified"),0)) && ((!ref($args{'pack_deps'})) ? 1 : (($err_pack_deps //= "Not of type boolean value"),0)); if ($err_pack_deps) { return [400, "Argument 'pack_deps' fails validation: $err_pack_deps"]; } }  if (exists($args{'pass_cmdline_object'})) { my $err_pass_cmdline_object; (!defined($args{'pass_cmdline_object'}) ? 1 :  ((!ref($args{'pass_cmdline_object'})) ? 1 : (($err_pass_cmdline_object //= "Not of type boolean value"),0))); if ($err_pass_cmdline_object) { return [400, "Argument 'pass_cmdline_object' fails validation: $err_pass_cmdline_object"]; } }  if (exists($args{'per_arg_json'})) { my $err_per_arg_json; ((defined($args{'per_arg_json'})) ? 1 : (($err_per_arg_json //= "Required but not specified"),0)) && ((!ref($args{'per_arg_json'})) ? 1 : (($err_per_arg_json //= "Not of type boolean value"),0)); if ($err_per_arg_json) { return [400, "Argument 'per_arg_json' fails validation: $err_per_arg_json"]; } }  if (exists($args{'per_arg_yaml'})) { my $err_per_arg_yaml; ((defined($args{'per_arg_yaml'})) ? 1 : (($err_per_arg_yaml //= "Required but not specified"),0)) && ((!ref($args{'per_arg_yaml'})) ? 1 : (($err_per_arg_yaml //= "Not of type boolean value"),0)); if ($err_per_arg_yaml) { return [400, "Argument 'per_arg_yaml' fails validation: $err_per_arg_yaml"]; } }  if (exists($args{'pod'})) { my $err_pod; ((defined($args{'pod'})) ? 1 : (($err_pod //= "Required but not specified"),0)) && ((!ref($args{'pod'})) ? 1 : (($err_pod //= "Not of type boolean value"),0)); if ($err_pod) { return [400, "Argument 'pod' fails validation: $err_pod"]; } } else { $args{'pod'} //= 1; }  if (exists($args{'prefer_lite'})) { my $err_prefer_lite; (!defined($args{'prefer_lite'}) ? 1 :  ((!ref($args{'prefer_lite'})) ? 1 : (($err_prefer_lite //= "Not of type boolean value"),0))); if ($err_prefer_lite) { return [400, "Argument 'prefer_lite' fails validation: $err_prefer_lite"]; } } else { $args{'prefer_lite'} //= 1; }  if (exists($args{'read_config'})) { my $err_read_config; (!defined($args{'read_config'}) ? 1 :  ((!ref($args{'read_config'})) ? 1 : (($err_read_config //= "Not of type boolean value"),0))); if ($err_read_config) { return [400, "Argument 'read_config' fails validation: $err_read_config"]; } }  if (exists($args{'read_env'})) { my $err_read_env; (!defined($args{'read_env'}) ? 1 :  ((!ref($args{'read_env'})) ? 1 : (($err_read_env //= "Not of type boolean value"),0))); if ($err_read_env) { return [400, "Argument 'read_env' fails validation: $err_read_env"]; } }  if (exists($args{'script_name'})) { my $err_script_name; (!defined($args{'script_name'}) ? 1 :  ((!ref($args{'script_name'})) ? 1 : (($err_script_name //= "Not of type text"),0))); if ($err_script_name) { return [400, "Argument 'script_name' fails validation: $err_script_name"]; } }  if (exists($args{'script_summary'})) { my $err_script_summary; (!defined($args{'script_summary'}) ? 1 :  ((!ref($args{'script_summary'})) ? 1 : (($err_script_summary //= "Not of type text"),0))); if ($err_script_summary) { return [400, "Argument 'script_summary' fails validation: $err_script_summary"]; } }  if (exists($args{'script_version'})) { my $err_script_version; (!defined($args{'script_version'}) ? 1 :  ((!ref($args{'script_version'})) ? 1 : (($err_script_version //= "Not of type text"),0))); if ($err_script_version) { return [400, "Argument 'script_version' fails validation: $err_script_version"]; } }  if (exists($args{'skip_format'})) { my $err_skip_format; (!defined($args{'skip_format'}) ? 1 :  ((!ref($args{'skip_format'})) ? 1 : (($err_skip_format //= "Not of type boolean value"),0))); if ($err_skip_format) { return [400, "Argument 'skip_format' fails validation: $err_skip_format"]; } }  if (exists($args{'ssl_verify_hostname'})) { my $err_ssl_verify_hostname; (!defined($args{'ssl_verify_hostname'}) ? 1 :  ((!ref($args{'ssl_verify_hostname'})) ? 1 : (($err_ssl_verify_hostname //= "Not of type boolean value"),0))); if ($err_ssl_verify_hostname) { return [400, "Argument 'ssl_verify_hostname' fails validation: $err_ssl_verify_hostname"]; } } else { $args{'ssl_verify_hostname'} //= 1; }  if (exists($args{'subcommands'})) { my $err_subcommands; ((defined($args{'subcommands'})) ? 1 : (($err_subcommands //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((ref($args{'subcommands'}) eq 'HASH') ? 1 : (($err_subcommands //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type hash"),0)) && ([push(@{$_sahv_dpath}, undef), ~~((!defined(List::Util::first(sub {!( ($_sahv_dpath->[-1] = $_), ((defined($args{'subcommands'}->{$_})) ? 1 : (($err_subcommands //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Required but not specified"),0)) && ((!ref($args{'subcommands'}->{$_})) ? 1 : (($err_subcommands //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type text"),0)) )}, sort keys(%{$args{'subcommands'}})))) ? 1 : (($err_subcommands //= (@$_sahv_dpath ? '@'.join("",map {"[$_]"} @$_sahv_dpath).": " : "") . "Not of type each field must be: text"),0)), pop(@{$_sahv_dpath})]->[1]); if ($err_subcommands) { return [400, "Argument 'subcommands' fails validation: $err_subcommands"]; } }  if (exists($args{'subcommands_from_package_functions'})) { my $err_subcommands_from_package_functions; (!defined($args{'subcommands_from_package_functions'}) ? 1 :  ((!ref($args{'subcommands_from_package_functions'})) ? 1 : (($err_subcommands_from_package_functions //= "Not of type boolean value"),0)) && (($args{'subcommands_from_package_functions'} ? 1:0) == (1 ? 1:0) ? 1 : (($err_subcommands_from_package_functions //= "Must have the value 1"),0))); if ($err_subcommands_from_package_functions) { return [400, "Argument 'subcommands_from_package_functions' fails validation: $err_subcommands_from_package_functions"]; } }  if (exists($args{'url'})) { my $err_url; ((defined($args{'url'})) ? 1 : (($err_url //= "Required but not specified"),0)) && (($args{'url'} = (!ref($args{'url'})) ? (do { my $url = URI->new($args{'url'}); if (!$url) { ['Invalid URL'] } else { [undef, $url] } }) : [undef,$args{'url'}]), defined($args{'url'}->[0]) ? (($err_url //= $args{'url'}->[0]), '') : (($args{'url'} = $args{'url'}->[1]), 1)) && ((Scalar::Util::blessed($args{'url'})) ? 1 : (($err_url //= "Not of type object"),0)) && (($args{'url'}->isa("URI")) ? 1 : (($err_url //= "Must be subclass of URI"),0)); if ($err_url) { return [400, "Argument 'url' fails validation: $err_url"]; } }  if (!exists($args{'url'})) { return [400, "Missing required argument: url"]; } if (exists($args{'use_cleanser'})) { my $err_use_cleanser; (!defined($args{'use_cleanser'}) ? 1 :  ((!ref($args{'use_cleanser'})) ? 1 : (($err_use_cleanser //= "Not of type boolean value"),0))); if ($err_use_cleanser) { return [400, "Argument 'use_cleanser' fails validation: $err_use_cleanser"]; } }  if (exists($args{'use_utf8'})) { my $err_use_utf8; (!defined($args{'use_utf8'}) ? 1 :  ((!ref($args{'use_utf8'})) ? 1 : (($err_use_utf8 //= "Not of type boolean value"),0))); if ($err_use_utf8) { return [400, "Argument 'use_utf8' fails validation: $err_use_utf8"]; } }  if (exists($args{'validate_args'})) { my $err_validate_args; ((defined($args{'validate_args'})) ? 1 : (($err_validate_args //= "Required but not specified"),0)) && ((!ref($args{'validate_args'})) ? 1 : (($err_validate_args //= "Not of type boolean value"),0)); if ($err_validate_args) { return [400, "Argument 'validate_args' fails validation: $err_validate_args"]; } } $_w_res = do { ## this line is put by Dist::Zilla::Plugin::Rinci::Wrap

    local $Data::Dump::INDENT = "    ";

    # XXX schema
    $args{ssl_verify_hostname} //= 1;
    $args{copt_version_enable} //= 1;
    $args{copt_help_enable}    //= 1;

    my $output_file = $args{output_file};

    my $script_name = $args{script_name};
    unless ($script_name) {
        if ($output_file eq '-') {
            $script_name = 'script';
        } else {
            $script_name = $output_file;
            $script_name =~ s!.+[\\/]!!;
        }
    }

    my $cmdline_mod = "Perinci::CmdLine::Any";
    my $cmdline_mod_ver = 0;
    if ($args{cmdline}) {
        my $val = $args{cmdline};
        if ($val eq 'any') {
            $cmdline_mod = "Perinci::CmdLine::Any";
        } elsif ($val eq 'classic') {
            $cmdline_mod = "Perinci::CmdLine::Classic";
        } elsif ($val eq 'lite') {
            $cmdline_mod = "Perinci::CmdLine::Lite";
        } elsif ($val eq 'inline') {
            $cmdline_mod = "Perinci::CmdLine::Inline";
        } else {
            $cmdline_mod = $val;
        }
    }

    my $subcommands;
    if ($args{subcommands} && keys %{$args{subcommands}}) {
        $subcommands = {};
        for my $sc_name (keys %{ $args{subcommands} }) {
            my ($sc_url, $sc_summary) = split /:/, $args{subcommands}{$sc_name}, 2;
            $subcommands->{$sc_name} = {
                url => $sc_url,
                (summary => $sc_summary) x !!(defined $sc_summary && length $sc_summary),
            };
        }
    } elsif ($args{subcommands_from_package_functions}) {
        my $res = _riap_request(child_metas => $args{url} => {detail=>1}, \%args);
        return [500, "Can't child_metas $args{url}: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        $subcommands = {};
        for my $uri (keys %{ $res->[2] }) {
            next unless $uri =~ /\A\w+\z/; # functions only
            my $meta = $res->[2]{$uri};
            if ($args{include_package_functions_match}) {
                next unless $uri =~ /$args{include_package_functions_match}/;
            }
            if ($args{exclude_package_functions_match}) {
                next if $uri =~ /$args{exclude_package_functions_match}/;
            }
            (my $sc_name = $uri) =~ s/_/-/g;
            $subcommands->{$sc_name} = {
                url     => "$args{url}$uri",
                (summary => $meta->{summary}) x !!(defined $meta->{summary}),
            };
        }
    }

    # request metadata to get summary (etc)
    my $meta;
    {
        my $res = _riap_request(meta => $args{url} => {}, \%args);
        if ($res->[0] == 200) {
            $meta = $res->[2];
        } else {
            warn "Can't meta $args{url}: $res->[0] - $res->[1]"
                if $args{-cmdline};
            $meta = {v=>1.1, _note=>'No meta', args=>{}};
        }
    }

    my $gen_sig = join(
        "",
        "# Note: This script is a CLI",
        ($meta->{args} ? " for Riap function $args{url}" : ""), # a quick hack to guess meta is func metadata (XXX should've done an info Riap request)
        "\n",
        "# and generated automatically using ", __PACKAGE__,
        " version ", ($Perinci::CmdLine::Gen::VERSION // '?'), "\n",
    );

    my $extra_modules = {};

    # generate code
    my $code;
    if ($cmdline_mod eq 'Perinci::CmdLine::Inline') {
        require Perinci::CmdLine::Inline;
        $cmdline_mod_ver = $Perinci::CmdLine::Inline::VERSION;
        my $res = Perinci::CmdLine::Inline::gen_inline_pericmd_script(
            url => "$args{url}",
            script_name => $args{script_name},
            script_summary => $args{script_summary},
            script_version => $args{script_version},
            subcommands => $subcommands,
            (default_subcommand => $args{default_subcommand}) x !!$args{default_subcommand},
            log => $args{log},
            (extra_urls_for_version => $args{extra_urls_for_version}) x !!$args{extra_urls_for_version},
            include => $args{load_module},
            code_after_shebang => $gen_sig,
            (code_before_parse_cmdline_options => $args{code_before_instantiate_cmdline}) x !!$args{code_before_instantiate_cmdline},
            (code_after_end => $args{code_after_end}) x !!$args{code_after_end},
            read_config => $args{read_config},
            config_filename => $args{config_filename},
            config_dirs => $args{config_dirs},
            read_env => $args{read_env},
            env_name => $args{env_name},
            shebang => $args{interpreter_path},
            (default_format => $args{default_format}) x !!$args{default_format},
            skip_format => $args{skip_format} ? 1:0,
            (use_cleanser => $args{use_cleanser} ? 1:0) x !!(defined $args{use_cleanser}),
            (use_utf8 => $args{use_utf8} ? 1:0) x !!(defined $args{use_utf8}),
            (default_dry_run => $args{default_dry_run} ? 1:0) x !!(defined $args{default_dry_run}),
            (allow_prereq => $args{allow_prereq}) x !!$args{allow_prereq},
            (per_arg_json => $args{per_arg_json} ? 1:0) x !!(defined $args{per_arg_json}),
            (per_arg_yaml => $args{per_arg_yaml} ? 1:0) x !!(defined $args{per_arg_yaml}),
            (pack_deps => $args{pack_deps}) x !!(defined $args{pack_deps}),
            (validate_args => $args{validate_args}) x !!(defined $args{validate_args}),
            (pod => $args{pod}) x !!(defined $args{pod}),
        );
        return $res if $res->[0] != 200;
        $code = $res->[2];
        for (keys %{ $res->[3]{'func.raw_result'}{req_modules} }) {
            $extra_modules->{$_} = $res->[3]{'func.raw_result'}{req_modules}{$_};
        }
    } else {
        $extra_modules->{'Log::ger'} = '0.027' if $args{log};
        # determine minimum required version
        if ($cmdline_mod =~ /\APerinci::CmdLine::(Lite|Any)\z/) {
            if ($cmdline_mod eq 'Perinci::CmdLine::Lite') {
                $cmdline_mod_ver = "1.820";
            } else {
                $extra_modules->{"Perinci::CmdLine::Lite"} = "1.820";
            }
        } elsif ($cmdline_mod =~ /\APerinci::CmdLine::Classic\z/) {
            $extra_modules->{"Perinci::CmdLine::Base"} = "1.820";
            $extra_modules->{"Perinci::CmdLine::Classic"} = "1.770";
        }

        $code = join(
            "",
            "#!", ($args{interpreter_path} // $^X), "\n",
            "\n",
            $gen_sig,
            "\n",
            "# DATE\n",
            "# DIST\n",
            "# VERSION\n",
            "\n",
            "use 5.010001;\n",
            "use strict;\n",
            "use warnings;\n",
            ($args{log} ? "use Log::ger;\n" : ""),
            "\n",

            ($args{load_module} && @{$args{load_module}} ?
                 join("", map {"use $_;\n"} @{$args{load_module}})."\n" : ""),

            "use $cmdline_mod",
            ($cmdline_mod eq 'Perinci::CmdLine::Any' &&
                 defined($args{prefer_lite}) && !$args{prefer_lite} ? " -prefer_lite=>0" : ""),
            ";\n\n",

            ($args{ssl_verify_hostname} ?
                 "" : '$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;' . "\n\n"),

            ($args{code_before_instantiate_cmdline} ? "# code_before_instantiate_cmdline\n" . $args{code_before_instantiate_cmdline} . "\n\n" : ""),

            "my \$cmdline = $cmdline_mod->new(\n",
            "    url => ", dump("$args{url}"), ",\n",
            (defined($subcommands) ? "    subcommands => " . indent("    ", dump($subcommands), {first_line_indent=>""}) . ",\n" : ""),
            "    program_name => " . dump($script_name) . ",\n",
            (defined($args{default_subcommand}) ? "    default_subcommand => " . dump($args{default_subcommand}) . ",\n" : ""),
            (defined($args{log}) ? "    log => " . dump($args{log}) . ",\n" : ""),
            ($args{default_log_level} ? "    log_level => " . dump($args{default_log_level}) . ",\n" : ""),
            (defined($args{pass_cmdline_object}) ? "    pass_cmdline_object => " . dump($args{pass_cmdline_object}) . ",\n" : ""),
            (defined($args{extra_urls_for_version}) ? "    extra_urls_for_version => " . dump($args{extra_urls_for_version}) . ",\n" : ""),
            (defined($args{read_config}) ? "    read_config => " . ($args{read_config} ? 1:0) . ",\n" : ""),
            (defined($args{config_filename}) ? "    config_filename => " . dump(ref($args{config_filename}) eq 'ARRAY' && @{$args{config_filename}}==1 ? $args{config_filename}[0] : $args{config_filename}) . ",\n" : ""),
            (defined($args{config_dirs}) ? "    config_dirs => " . dump($args{config_dirs}) . ",\n" : ""),
            (defined($args{read_env})    ? "    read_env => " . ($args{read_env} ? 1:0) . ",\n" : ""),
            (defined($args{env_name})    ? "    env_name => " . dump($args{env_name}) . ",\n" : ""),
            ($args{default_format} ? "    default_format => " . dump($args{default_format}) . ",\n" : ""),
            ($args{skip_format} ? "    skip_format => 1,\n" : ""),
            (defined($args{use_utf8}) ? "    use_utf8 => " . dump($args{use_utf8}) . ",\n" : ""),
            (defined($args{use_cleanser}) ? "    use_cleanser => " . dump($args{use_cleanser}) . ",\n" : ""),
            (defined($args{default_dry_run}) ? "    default_dry_run => " . dump($args{default_dry_run}) . ",\n" : ""),
            (defined($args{per_arg_json}) ? "    per_arg_json => " . dump($args{per_arg_json}) . ",\n" : ""),
            (defined($args{per_arg_yaml}) ? "    per_arg_yaml => " . dump($args{per_arg_yaml}) . ",\n" : ""),
            (defined($args{validate_args}) ? "    validate_args => " . dump($args{validate_args}) . ",\n" : ""),
            ");\n\n",

            (!$args{copt_version_enable} ? "delete \$cmdline->{common_opts}{version};\n\n" :
                 defined($args{copt_version_getopt}) ? "\$cmdline->{common_opts}{version}{getopt} = ".dump($args{copt_version_getopt}).";\n\n" : ""),

            (!$args{copt_help_enable} ? "delete \$cmdline->{common_opts}{help};\n\n" :
                 defined($args{copt_help_getopt}) ? "\$cmdline->{common_opts}{help}{getopt} = ".dump($args{copt_help_getopt}).";\n\n" : ""),

            "\$cmdline->run;\n",
            "\n",
        );

        # abstract line
        $code .= "# ABSTRACT: " . ($args{script_summary} // $meta->{summary} // $script_name) . "\n";

        # podname
        $code .= "# PODNAME: $script_name\n";

        $code .= "# code_after_end\n" . $args{code_after_end} . "\n\n"
            if $args{code_after_end};

    } # END generate code

    if ($output_file ne '-') {
        log_trace("Outputing result to %s ...", $output_file);
        if ((-f $output_file) && !$args{overwrite}) {
            return [409, "Output file '$output_file' already exists (please use --overwrite if you want to override)"];
        }
        open my($fh), ">", $output_file
            or return [500, "Can't open '$output_file' for writing: $!"];

        print $fh $code;
        close $fh
            or return [500, "Can't write '$output_file': $!"];

        chmod 0755, $output_file or do {
            log_warn("Can't 'chmod 0755, $output_file': $!");
        };

        my $output_name = $output_file;
        $output_name =~ s!.+[\\/]!!;

        if (which("shcompgen") && which($output_name)) {
            log_trace("We have shcompgen in PATH and output ".
                          "$output_name is also in PATH, running shcompgen ...");
            system "shcompgen", "generate", $output_name;
        }

        $code = "";
    }

    [200, "OK", $code, {
        'func.cmdline_module' => $cmdline_mod,
        'func.cmdline_module_version' => $cmdline_mod_ver,
        'func.cmdline_module_inlined' => ($cmdline_mod eq 'Perinci::CmdLine::Inline' ? 1:0),
        'func.extra_modules' => $extra_modules,
        'func.script_name' => 0,
    }];
};      unless (ref($_w_res) eq "ARRAY" && $_w_res->[0]) { return [500, 'BUG: Sub Perinci::CmdLine::Gen::gen_pericmd_script does not produce envelope']; } return $_w_res; } ## this line is put by Dist::Zilla::Plugin::Rinci::Wrap

# alias
{
    no warnings 'once';
    *gen_perinci_cmdline_script = \&gen_pericmd_script;
    $SPEC{gen_perinci_cmdline_script} = $SPEC{gen_pericmd_script};
}

1;
# ABSTRACT: Generate Perinci::CmdLine CLI script

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Gen - Generate Perinci::CmdLine CLI script

=head1 VERSION

This document describes version 0.491 of Perinci::CmdLine::Gen (from Perl distribution Perinci-CmdLine-Gen), released on 2019-06-20.

=head1 FUNCTIONS


=head2 gen_pericmd_script

Usage:

 gen_pericmd_script(%args) -> [status, msg, payload, meta]

Generate Perinci::CmdLine CLI script.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_prereq> => I<array[perl::modname]>

Allow script to depend on these modules.

Sometimes, as in the case of using C<Perinci::CmdLine::Inline>, dependency to
some modules (e.g. non-core XS modules) are prohibited because the goal is to
have a free-standing script. This option allows whitelisting some extra modules.

If you use C<Perinci::CmdLine::Inline>, this option will be passed to it.

=item * B<cmdline> => I<perl::modname> (default: "Perinci::CmdLine::Any")

Specify module to use.

=item * B<code_after_end> => I<str>

=item * B<code_before_instantiate_cmdline> => I<str>

=item * B<config_dirs> => I<array[str]>

Will be passed to Perinci::CmdLine constructor.

=item * B<config_filename> => I<str|hash|array[str|hash]>

Will be passed to Perinci::CmdLine constructor.

=item * B<copt_help_enable> => I<bool> (default: 1)

=item * B<copt_help_getopt> => I<str>

=item * B<copt_version_enable> => I<bool> (default: 1)

=item * B<copt_version_getopt> => I<str>

=item * B<default_dry_run> => I<bool>

Whether to set default_dry_run, will be passed to Perinci::CmdLine constructor.

=item * B<default_format> => I<str>

Set default format.

=item * B<default_log_level> => I<str>

=item * B<default_subcommand> => I<str>

Will be passed to Perinci::CmdLine constructor.

=item * B<env_name> => I<str>

Will be passed to Perinci::CmdLine constructor.

=item * B<exclude_package_functions_match> => I<re>

Exclude package functions matching this pattern.

=item * B<extra_urls_for_version> => I<array[str]>

Will be passed to Perinci::CmdLine constructor.

=item * B<include_package_functions_match> => I<re>

Only include package functions matching this pattern.

=item * B<interpreter_path> => I<str>

What to put on shebang line.

=item * B<load_module> => I<array[perl::modname]>

Load extra modules.

=item * B<log> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<output_file> => I<filename> (default: "-")

Path to output file.

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite output if previously exists.

=item * B<pack_deps> => I<bool>

Whether to pack dependencies in Perinci::CmdLine::Inline script.

Will be passed to L<Perinci::CmdLine>'s C<gen_inline_pericmd_script>'s
C<pack_deps> option.

=item * B<pass_cmdline_object> => I<bool>

Will be passed to Perinci::CmdLine constructor.

Currently irrelevant when generating with Perinci::CmdLine::Inline.

=item * B<per_arg_json> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<per_arg_yaml> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<pod> => I<bool> (default: 1)

Whether to generate POD or not.

Currently only Perinci::CmdLine::Inline generates POD.

=item * B<prefer_lite> => I<bool> (default: 1)

Prefer Perinci::CmdLine::Lite backend.

=item * B<read_config> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<read_env> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<script_name> => I<str>

=item * B<script_summary> => I<str>

=item * B<script_version> => I<str>

Use this for version number instead.

=item * B<skip_format> => I<bool>

Assume that function returns raw text which needs no formatting.

=item * B<ssl_verify_hostname> => I<bool> (default: 1)

If set to 0, will add: $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;' to code.

=item * B<subcommands> => I<hash>

Hash of subcommand entries, where each entry is "url[:summary]".

An optional summary can follow the URL, e.g.:

 URL[:SUMMARY]

Example (on CLI):

 --subcommand add=/My/App/add_item --subcommand bin='/My/App/bin_item:Delete an item'

=item * B<subcommands_from_package_functions> => I<bool>

Form subcommands from functions under package's URL.

This is an alternative to the C<subcommands> option. Instead of specifying each
subcommand's name and URL, you can also specify that subcommand names are from
functions under the package URL in C<url>. So for example if C<url> is C</My/App/>,
hen all functions under C</My/App> are listed first. If the functions are:

 foo
 bar
 baz_qux

then the subcommands become:

 foo => /My/App/foo
 bar => /My/App/bar
 "baz-qux" => /My/App/baz_qux

=item * B<url>* => I<riap::url>

URL to function (or package, if you have subcommands).

=item * B<use_cleanser> => I<bool>

Whether to use data cleansing before outputting to JSON.

=item * B<use_utf8> => I<bool>

Whether to set utf8 flag on output, will be passed to Perinci::CmdLine constructor.

=item * B<validate_args> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 gen_perinci_cmdline_script

Usage:

 gen_perinci_cmdline_script(%args) -> [status, msg, payload, meta]

Generate Perinci::CmdLine CLI script.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_prereq> => I<array[perl::modname]>

Allow script to depend on these modules.

Sometimes, as in the case of using C<Perinci::CmdLine::Inline>, dependency to
some modules (e.g. non-core XS modules) are prohibited because the goal is to
have a free-standing script. This option allows whitelisting some extra modules.

If you use C<Perinci::CmdLine::Inline>, this option will be passed to it.

=item * B<cmdline> => I<perl::modname> (default: "Perinci::CmdLine::Any")

Specify module to use.

=item * B<code_after_end> => I<str>

=item * B<code_before_instantiate_cmdline> => I<str>

=item * B<config_dirs> => I<array[str]>

Will be passed to Perinci::CmdLine constructor.

=item * B<config_filename> => I<str|hash|array[str|hash]>

Will be passed to Perinci::CmdLine constructor.

=item * B<copt_help_enable> => I<bool> (default: 1)

=item * B<copt_help_getopt> => I<str>

=item * B<copt_version_enable> => I<bool> (default: 1)

=item * B<copt_version_getopt> => I<str>

=item * B<default_dry_run> => I<bool>

Whether to set default_dry_run, will be passed to Perinci::CmdLine constructor.

=item * B<default_format> => I<str>

Set default format.

=item * B<default_log_level> => I<str>

=item * B<default_subcommand> => I<str>

Will be passed to Perinci::CmdLine constructor.

=item * B<env_name> => I<str>

Will be passed to Perinci::CmdLine constructor.

=item * B<exclude_package_functions_match> => I<re>

Exclude package functions matching this pattern.

=item * B<extra_urls_for_version> => I<array[str]>

Will be passed to Perinci::CmdLine constructor.

=item * B<include_package_functions_match> => I<re>

Only include package functions matching this pattern.

=item * B<interpreter_path> => I<str>

What to put on shebang line.

=item * B<load_module> => I<array[perl::modname]>

Load extra modules.

=item * B<log> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<output_file> => I<filename> (default: "-")

Path to output file.

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite output if previously exists.

=item * B<pack_deps> => I<bool>

Whether to pack dependencies in Perinci::CmdLine::Inline script.

Will be passed to L<Perinci::CmdLine>'s C<gen_inline_pericmd_script>'s
C<pack_deps> option.

=item * B<pass_cmdline_object> => I<bool>

Will be passed to Perinci::CmdLine constructor.

Currently irrelevant when generating with Perinci::CmdLine::Inline.

=item * B<per_arg_json> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<per_arg_yaml> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<pod> => I<bool> (default: 1)

Whether to generate POD or not.

Currently only Perinci::CmdLine::Inline generates POD.

=item * B<prefer_lite> => I<bool> (default: 1)

Prefer Perinci::CmdLine::Lite backend.

=item * B<read_config> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<read_env> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=item * B<script_name> => I<str>

=item * B<script_summary> => I<str>

=item * B<script_version> => I<str>

Use this for version number instead.

=item * B<skip_format> => I<bool>

Assume that function returns raw text which needs no formatting.

=item * B<ssl_verify_hostname> => I<bool> (default: 1)

If set to 0, will add: $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;' to code.

=item * B<subcommands> => I<hash>

Hash of subcommand entries, where each entry is "url[:summary]".

An optional summary can follow the URL, e.g.:

 URL[:SUMMARY]

Example (on CLI):

 --subcommand add=/My/App/add_item --subcommand bin='/My/App/bin_item:Delete an item'

=item * B<subcommands_from_package_functions> => I<bool>

Form subcommands from functions under package's URL.

This is an alternative to the C<subcommands> option. Instead of specifying each
subcommand's name and URL, you can also specify that subcommand names are from
functions under the package URL in C<url>. So for example if C<url> is C</My/App/>,
hen all functions under C</My/App> are listed first. If the functions are:

 foo
 bar
 baz_qux

then the subcommands become:

 foo => /My/App/foo
 bar => /My/App/bar
 "baz-qux" => /My/App/baz_qux

=item * B<url>* => I<riap::url>

URL to function (or package, if you have subcommands).

=item * B<use_cleanser> => I<bool>

Whether to use data cleansing before outputting to JSON.

=item * B<use_utf8> => I<bool>

Whether to set utf8 flag on output, will be passed to Perinci::CmdLine constructor.

=item * B<validate_args> => I<bool>

Will be passed to Perinci::CmdLine constructor.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Gen>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Gen>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Gen>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
