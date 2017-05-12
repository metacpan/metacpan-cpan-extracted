package Template::JavaScript;
BEGIN {
  $Template::JavaScript::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Template::JavaScript::VERSION = '0.01';
}
# vim: ft=perl ts=4 sw=4 et:

use v5.010.1;
use Any::Moose;

# For compiling our output
use JavaScript::V8;

# For generating our output
use Template;

# Utility functions
use JavaScript::Value::Escape;

=head1 NAME

Template::JavaScript - A templating engine using the L<JavaScript::V8> module

=head1 SYNOPSIS

    use Test::More qw( no_plan );
    use Template::JavaScript;

    my $tj = Template::JavaScript->new();

    $tj->output( \my $out );

    $tj->tmpl_string( <<'' );
    before
    % for( var i = 3; i ; i-- ){
      this is a loop
    % }
    after

    $tj->run;

    is( $out, <<'', 'can run simple JS code (loops)' );
    before
      this is a loop
      this is a loop
      this is a loop
    after

=head1 DESCRIPTION

This is a very simple template to JavaScript compiler. We compile
either templates passed in as strings or as a file with L<Template
Toolkit|Template>, so you can do includes etc. like L<Template>
normally does it.

Once L<Template> has run we apply our own syntax, which is that any
line beginning with C<%> is JavaScript and any other line is output
verbatim.

After the compilation phase (which you can cache) we execute the
template with L<JavaScript::V8>. So your templates will run very fast
in the V8 JIT. We provide ways to pass variables and functions back &
forth to L<JavaScript::V8> through its normal facilities.

=cut

has bind => (
    is            => 'ro',
    isa           => 'ArrayRef[Any]',
    default       => sub { +[] },
    documentation => 'Things to bind',
);

has template => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Things to bind',
);

has include_path => (
    is            => 'rw',
    isa           => 'Str|ArrayRef',
    documentation => 'The include path for the templates',
);

has output => (
    is            => 'rw',
    isa           => 'Any',
);

has _context => (
    is            => 'ro',
    isa           => 'JavaScript::V8::Context',
    lazy_build    => 1,
    documentation => '',
);

sub _build__context {
    JavaScript::V8::Context->new;
}

has _js_code => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Compiled JS code',
);

has _result => (
    is            => 'rw',
    isa           => 'Str',
    default       => '',
    documentation => 'Result accumulator',
);

has _tt => (
    is            => 'rw',
    isa           => 'Template',
    lazy_build    => 1,
    documentation => 'Our Template Toolkit object',
);

sub _build__tt {
    my ($self) = @_;

    my $tt = Template->new({
        INCLUDE_PATH => $self->include_path, # or list ref
        INTERPOLATE  => 0,         # expand "$var" in plain text
        POST_CHOMP   => 0,         # cleanup whitespace 
        EVAL_PERL    => 0,         # evaluate Perl code blocks
        ABSOLUTE     => 1,         # all includes are absolute
    });

    return $tt;
}

sub BUILD {
    my ($self) = @_;
    my $context = $self->_context;

    # Standard library
    $context->bind_function( say => sub {
        $self->{_result} .= $_[0];
        $self->{_result} .= "\n";
    });
    $context->bind_function( whisper => sub {
        $self->{_result} .= $_[0];
    });

    # User-supplied stuff
    my $bind = $self->bind;

    for my $b (@$bind) {
        $context->bind(@$b);
    }

    return;
}

sub tmpl_string {
    my ($self, $string) = @_;

    my $output;
    $self->_tt->process(\$string, {}, \$output) || die $self->_tt->error;

    $self->template( $output );
}

sub tmpl_fh {
    my ($self, $fh) = @_;

    my $code;
    {
        local $/;
        $code = < $fh >;
    }

    my $output;
    $self->_tt->process(\$code, {}, \$output) || die $self->_tt->error;

    $self->template( $output );
}

sub tmpl_file {
    my ($self, $file) = @_;

    my $output;
    $self->_tt->process($file, {}, \$output) || die $self->_tt->error;

    $self->template( $output );
}

sub compile {
    my ($self) = @_;
    my $context = $self->_context;

    my $js_code = '';

    for my $line (split /^/, $self->template) {
        chomp $line;
        if ( substr($line, 0, 1) ne '%' ) {
            my @parts;
            # Parse inline variables
            while($line =~ /(.*?)<%\s*([^%]*?)\s*%>(.*)/s) {
                push (@parts, ( [ 'str', $1 ], [ 'expr', $2 ] ));
                $line = $3;
            }
            push (@parts, ['str', $line]) if ($line ne '');
            # use Data::Dumper;
            # say STDERR "begin";
            # say STDERR Dumper \@parts;
            # say STDERR "end";

            if (@parts == 0 || @parts == 1) {
                my $escaped = javascript_value_escape($line);
                $js_code .= qq[;say('$escaped');];
            } else {
            # join them up
                $js_code .= join '', map {
                    my ($what, $value) = @$_;
                    my $ret;
                    if ($what eq 'str') {
                        my $escaped = javascript_value_escape($value);
                        $ret = qq[;whisper('$escaped');];
                    } elsif ($what eq 'expr') {
                        $ret = ";whisper($value);";
                    } else {
                        die;
                    }
                } @parts;
                $js_code .= qq[;whisper("\\n");];
            }
        } else {
            substr($line, 0, 1, '');

            $js_code .= $line . "\n";
        }
    }

    # say STDERR "CODE:{$js_code}";

    $self->_js_code( $js_code );
}

sub run {
    my ($self) = @_;

    my $js_code = '';
    unless ( $js_code = $self->_js_code ){
        $self->compile;
        $js_code = $self->_js_code;
    }

    my $context = $self->_context;

    unless ( my $retval = $context->eval($js_code) ){
        $retval //= '<undef>';
        $@ //= '<unknown error>';
        die "retval:[$retval] \$\@:[$@]";
    }

    given ( ref $self->{output} ) {
        when ( 'SCALAR' ){
            ${ $self->{output} } = $self->{_result};
        }
        when ( 'GLOB' ){
            print { $self->{output} } $self->{_result};
        }
    }
}

__PACKAGE__->meta->make_immutable;
