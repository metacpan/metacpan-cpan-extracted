package Tapir::Server::Handler::Signatures;

use strict;
use warnings;
use Devel::Declare::Context::Simple;

use base qw(Exporter);
our @EXPORT = qw(set_service);

our $ALLOW_REDEFINE = 0;

sub set_service ($) {
    my $class = caller;
    $class->service(@_);
}

sub import {
    my ($class, %args) = @_;
    my $caller = caller;
    $class->setup_for($caller, \%args);

    # Allow Exporter to do its thing
    $class->export_to_level(1, @_);
}

sub setup_for {
    my ($class, $pkg, $args) = @_;

    # Create a wrapper for the parser() call to capture $pkg
    my $parser = sub {
        my $context = Devel::Declare::Context::Simple->new(into => $pkg);
        parser($context, @_);
    };

    Devel::Declare->setup_for(
        $pkg,
        { method => { const => $parser } }
    );
    {
        no strict 'refs';
        *{ $pkg . '::method' } = sub (&) {};
    }
}

sub parser {
    my $ctx = shift;
    $ctx->init(@_);

    $ctx->skip_declarator;
    my $name  = $ctx->strip_name;
    my $proto = $ctx->strip_proto;
    my $attrs = parse_attrs($ctx->strip_attrs);

    # Figure out what to inject based on the prototype
    my $inject = parse_proto($proto);

    # Add the method name onto the Handler->methods() accessor
    my $pkg = $ctx->{into};

    # Record some meta information about this in the class accessors
    my $after_block = '';
    my $modifier = $attrs ? ", \\'$attrs\\'" : '';
    $after_block = "$pkg->add_method(\\'$name\\'$modifier);";

    # Ensure that ';' occurs at the end of the block
    $inject = $ctx->scope_injector_call("; $after_block") . $inject;

    # Do the inject
    $ctx->inject_if_block($inject);

    if (defined $name) {
        $name = join('::', $ctx->get_curstash_name(), $name)
            unless ($name =~ /::/);
        $ctx->shadow(sub (&) {
            no strict 'refs';
            # In testing, it's convenient to redefine methods over and over; let's allow that
            # via the class global $ALLOW_REDEFINE
            if ($ALLOW_REDEFINE) {
                no warnings 'redefine';
                *{$name} = shift;
            }
            else {
                *{$name} = shift;
            }
        });
    }
    else {
        $ctx->shadow(sub (&) { shift });
    }
}

sub parse_attrs {
    my $attrs = shift;
    $attrs ||= '';

    return '' if $attrs eq '';

    $attrs =~ s/^://;
    $attrs =~ s/^\s+//;
    $attrs =~ s/\s+$//;

    return $attrs;
}

sub parse_proto {
    my $proto = shift;
    $proto ||= '';

    my $inject = "my (\$class, \$call) = \@_;";

    foreach my $part (split /\s* , \s*/x, $proto) {
        # scalar '$var'
        if ($part =~ m{\$(\S+)}) {
            $inject .= "my $part = \$call->arguments->field_named('$1')->value_plain();";
        }
        else {
            die "Unrecognized handler signature '$proto' (failed at '$part')";
        }
    }

    return $inject;
}

1;
