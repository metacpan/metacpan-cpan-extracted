use 5.10.1;
use strict;
use warnings;

package Pod::Elemental::Transformer::Splint;

# ABSTRACT: Documentation from class metadata
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1202';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use Safe::Isa;
use Try::Tiny;
use List::UtilsBy 'extract_by';
use Types::Standard qw/Str ArrayRef HashRef/;
use Module::Load qw/load/;
use Ref::Util qw/is_arrayref/;
use lib 'lib';

with qw/Pod::Elemental::Transformer Pod::Elemental::Transformer::Splint::Util/;

has command_name => (
    is => 'rw',
    isa => Str,
    default => ':splint',
);
has default_type_library => (
    is => 'rw',
    isa => Str,
    default => 'Types::Standard',
    predicate => 'has_default_type_library',
);
has type_libraries => (
    is => 'rw',
    isa => HashRef,
    traits => ['Hash'],
    handles => {
        get_library_for_type => 'get',
    },
);
has classmeta => (
    is => 'rw',
    predicate => 'has_classmeta',
);
has attribute_renderer => (
    is => 'rw',
    isa => ArrayRef[HashRef[Str]],
    traits => [qw/Array/],
    default => sub {
        [
            { for => 'HTML', class => 'HtmlDefault' },
            { for => 'markdown', class => 'HtmlDefault' },
        ],
    },
    handles => {
        all_attribute_renderers => 'elements',
    }
);
has method_renderer => (
    is => 'rw',
    isa => ArrayRef[HashRef[Str]],
    traits => [qw/Array/],
    default => sub {
        [
            { for => 'HTML', class => 'HtmlDefault' },
            { for => 'markdown', class => 'HtmlDefault' },
        ],
    },
    handles => {
        all_method_renderers => 'elements',
    }
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = shift;

    my $type_libraries = {};

    if(exists $args->{'type_libraries'}) {
        my $lib = $args->{'type_libraries'};
        $lib =~ s{([^\h]+=)}{---$1}g;
        $lib =~ s{^---}{};
        $lib =~ s{\h}{}g;
        my @libraries = split /---/ => $lib;

        foreach my $librarydata (@libraries) {
            my($library, $typesdata) = split /=/ => $librarydata;
            my @types = split /,/ => $typesdata;

            foreach my $type (@types) {
                $type_libraries->{ $type } = $library;
            }
        }
    }
    $args->{'type_libraries'} = $type_libraries;

    my $attribute_renderers = [];
    my $method_renderers = [];


    if(exists $args->{'attribute_renderer'}) {
        my @renderers = split m{,\s+}, $args->{'attribute_renderer'};

        for my $renderer (@renderers) {
            my($format, $class) = split m/=/, $renderer;
            push @{ $attribute_renderers } => { for => $format, class => $class };
        }
        $args->{'attribute_renderer'} = $attribute_renderers;
    }
    if(exists $args->{'method_renderer'}) {
        my @renderers = split m{,\s+}, $args->{'method_renderer'};

        for my $renderer (@renderers) {
            my($format, $class) = split m/=/, $renderer;
            $renderer = { for => $format, class => $class };
            push @{ $method_renderers } => { for => $format, class => $class };
        }
        $args->{'method_renderer'} = $method_renderers;
    }
    $class->$orig($args);
};

sub BUILD {
    my $self = shift;

    my $base = 'Pod::Elemental::Transformer::Splint';

    TYPE:
    foreach my $type (qw/attribute method/) {
        my $all_method = sprintf 'all_%s_renderers', $type;

        RENDERER:
        foreach my $renderer ($self->$all_method) {
            my $role = sprintf '%s::%sRenderer', $base, ucfirst $type;
            my $classname = sprintf '%s::%s', $role, $renderer->{'class'};

            try {
                load $classname;
            }
            catch {
                die "Can't use $classname as renderer: $_";
            };

            if(!$classname->does($role)) {
                die "$classname doesn't do the $role role";
            }

            $renderer->{'renderer'} = $classname->new(for => $renderer->{'for'});
        }
    }
}

sub transform_node {
    my $self = shift;
    my $node = shift;

    CHILD:
    foreach my $child (@{ $node->children }) {

        my $line_start = substr($child->content, 0 => length ($self->command_name) + 1);
        next CHILD if $line_start ne sprintf '%s ', $self->command_name;

        my($prefix, $action, $param, $data) = split m/\h+/, $child->content, 4;

        if($action eq 'classname' && defined $param) {
            eval "use $param";
            die "Can't use $param: $@" if $@;

            $self->classmeta($param->meta);
            $child->content('');

            next CHILD;
        }
        next CHILD if !$self->has_classmeta;

        if($action eq 'attributes' && scalar $self->classmeta->get_attribute_list) {

            my @attributes = map { $self->classmeta->get_attribute($_) } $self->classmeta->get_attribute_list;

            my @unwanted = extract_by { $_->does('Documented') && !$_->documentation_order } @attributes;

            my @custom_sort_order_attrs   = sort { $a->documentation_order <=> $b->documentation_order || $a->name cmp $b->name } extract_by { $_->does('Documented') && $_->documentation_order < 1000 }  @attributes;
            my @docced_not_in_constr_attr = sort { $a->name cmp $b->name } extract_by { !defined $_->init_arg && $_->does('Documented') } @attributes;
            my @not_in_constructor_attrs  = sort { $a->name cmp $b->name } extract_by { !defined $_->init_arg }  @attributes;
            my @required_attrs            = sort { $a->name cmp $b->name } extract_by { $_->is_required }        @attributes;
            my @documented_attrs          = sort { $a->name cmp $b->name } extract_by { $_->does('Documented') } @attributes;
            my @the_rest                  = sort { $a->name cmp $b->name } @attributes;

            my @wanted_attributes = (@custom_sort_order_attrs, @required_attrs, @documented_attrs, @the_rest, @docced_not_in_constr_attr, @not_in_constructor_attrs);
            #* First attributes with documentation
            #* then attributes available in constructor
            #* then required attributes
            #* and then alphabetical
            #my @attribute_names = sort {
            #                             ($a->does('Documented') && $a->has_documentation_order ? $a->documentation_order : 1000) <=> ($b->does('Documented') && $b->has_documentation_order ? $b->documentation_order : 1000)
            #                          || ($b->init_arg // 0) <=> ($a->init_arg // 0)
            #                          || ($b->is_required || 0) <=> ($a->is_required || 0)
            #                          ||  $a->name cmp $b->name
            #                      }
            #                      map { $self->classmeta->get_attribute($_) }
            #                      $self->classmeta->get_attribute_list;
            my $content = '';

            ATTR:
            foreach my $attr (@wanted_attributes) {
                next ATTR if $attr->does('Documented') && $attr->has_documentation_order && $attr->documentation_order == 0;

                $content .= sprintf "\n=head2 %s\n", $attr->name;
                my $prepared_attr = $self->prepare_attr($attr);
                foreach my $attribute_renderer ($self->all_attribute_renderers) {
                    $content .= $attribute_renderer->{'renderer'}->render_attribute($prepared_attr);
                }

            }
            $child->content($content);
        }

        if($action eq 'method') {
            if(!$self->classmeta->has_method($param)) {
                $child->content('');
                return;
            }

            my $method = $self->classmeta->get_method($param);
            my $content = sprintf "\n=head2 %s\n", $method->name;
            my $prepared_method = $self->prepare_method($method);

            foreach my $method_renderer ($self->all_method_renderers) {
                $content .= $method_renderer->{'renderer'}->render_method($prepared_method);
            }
            $child->content($content);

        }
        if($action eq 'methods') {
            my $content = '';

            METHOD:
            foreach my $method_name ($self->classmeta->get_method_list) {
                my $method = $self->classmeta->get_method($method_name);
                $content = sprintf "\n=head2 %s\n", $method->name;
                my $prepared_method = $self->prepare_method($method);

                foreach my $method_renderer ($self->all_method_renderers) {
                    $content .= $method_renderer->render_method($prepared_method);
                }
            }
            $child->content($content);
        }
    }
}
sub prepare_attr {
    my $self = shift;
    my $attr = shift;

    my $settings = {
        type => ($attr->type_constraint ? $self->make_type_string($attr->type_constraint) : undef),
        required_text => $self->required_text($attr->is_required),
        is_text => $self->is_text($attr),
        default => $attr->default,
        is_default_a_coderef => !!$attr->is_default_a_coderef(),
        has_init_arg => defined $attr->init_arg ? 1 : 0,
        documentation_default => $attr->does('Documented') ? $attr->documentation_default : undef,
    };

    my $documentation_alts = [];
    if($attr->does('Documented') && $attr->has_documentation_alts) {
        my $documentation = $attr->documentation_alts;

        foreach my $key (sort grep { $_ ne '_' } keys %{ $documentation }) {
            push @{ $documentation_alts } => [ $key, $documentation->{ $key } ];
        }
    }
    return {
        settings => $settings,
        documentation_alts => $documentation_alts,
        $attr->does('Documented') && $attr->has_documentation ? (documentation => $attr->documentation) : (),
    };
}

sub prepare_method {
    my $self = shift;
    my $method = shift;

    my $positional_params = [];
    my $named_params = [];

    my $try_signature = undef;

    try {
        $try_signature = $method->signature;
    }
    finally { };
    return { map { $_ => [] } qw/positional_params named_params return_types/ } if !ref $try_signature;

    foreach my $param ($method->signature->positional_params) {
        push @$positional_params => {
            name => $param->name,
            %{ $self->prepare_param($param) },
        };
    }
    if($method->signature->has_slurpy) {
        my $slurpy = $method->signature->slurpy_param;

        push @$positional_params => {
            name => $slurpy->name,
            %{ $self->prepare_param($slurpy) },
        };
    }

    foreach my $param (sort { $a->optional <=> $b->optional || $a->name cmp $b->name } $method->signature->named_params) {
        my $name = $param->name;
        $name =~ s{[\@\$\%]}{};
        push @$named_params => {
            name => $param->name,
            name_without_sigil => $name,
            %{ $self->prepare_param($param) },
        };
    }

    my $all_return_types = [];
    foreach my $return_types ($method->signature->return_types) {

        foreach my $return_type (@$return_types) {
            next if !$return_type->$_can('type');

            my($docs, $method_doc) = $self->get_docs($return_type);
            push @$all_return_types => {
                type => $self->make_type_string($return_type->type),
                docs => $docs,
                method_doc => $method_doc,
            };
        }
    }

    my $data = {
        positional_params => $positional_params,
        named_params => $named_params,
        return_types => $all_return_types,
    };

    return $data;

}

sub get_docs {
    my $self = shift;
    my $thing = shift;

    my $docs = [];
    my $method_doc = undef;

    if(exists $thing->traits->{'doc'} && ref $thing->traits->{'doc'} eq 'ARRAY') {
        $docs = [ split /\n/ => join "\n" => @{ $thing->traits->{'doc'} } ];

        if(index ($docs->[-1], 'method_doc|') == 0) {
            $method_doc = substr pop @{ $docs }, 11;
        }
    }
    return ($docs, $method_doc);
}

sub prepare_param {
    my $self = shift;
    my $param = shift;

    my($docs, $method_doc) = $self->get_docs($param);

    my $prepared = {
            type => $self->make_type_string($param->type),
            default => defined $param->default ? $param->default->() : undef,
            default_when => $param->default_when,
            has_default => defined $param->default ? 1 : 0,
            traits => [ sort grep { $_ && $_ ne 'doc' && $_ ne 'optional' } ($param->traits, ($param->coerce ? 'coerce' : () ) ) ],
            required_text => $self->required_text(!$param->optional),
            is_required => !$param->optional,
            method_doc => $method_doc,
            docs => $docs,
    };

    return $prepared;
}

sub required_text {
    my $self = shift;
    my $value = shift;
    return $value ? 'required' : 'optional';
}
sub is_text {
    my $self = shift;
    my $attr = shift;

    return $attr->has_write_method ? 'read/write' : 'read-only';
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Splint - Documentation from class metadata



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10.1+-blue.svg" alt="Requires Perl 5.10.1+" />
<a href="http://cpants.cpanauthors.org/release/CSSON/Pod-Elemental-Transformer-Splint-0.1202"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Pod-Elemental-Transformer-Splint/0.1202" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Pod-Elemental-Transformer-Splint%200.1202"><img src="http://badgedepot.code301.com/badge/cpantesters/Pod-Elemental-Transformer-Splint/0.1202" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-81.4%-orange.svg" alt="coverage 81.4%" />
</p>

=end html

=head1 VERSION

Version 0.1202, released 2020-12-26.

=head1 SYNOPSIS

    # in weaver.ini
    [-Transformer / Splint]
    transformer = Splint

=head1 DESCRIPTION

Pod::Elemental::Transformer::Splint uses L<MooseX::AttributeDocumented> to add inlined documentation about attributes to pod.
If you write your classes with L<Moops> you can also document method signatures with L<Kavorka::TraitFor::Parameter::doc> (and L<::ReturnType::doc|Kavorka::TraitFor::ReturnType::doc>).

A class defined like this:

    package My::Class;

    use Moose;

    has has_brakes => (
        is => 'ro',
        isa => Bool,
        default => 1,
        traits => ['Documented'],
        documentation => 'Does the bike have brakes?',
        documentation_alts => {
            0 => 'Hopefully a track bike',
            1 => 'Always nice to have',
        },
    );

    =pod

    :splint classname My::Class

    :splint attributes

    =cut

Will render like this (to html):

I<begin>

=begin HTML

<h2 id="has_brakes">has_brakes</h2>

<table cellpadding="0" cellspacing="0">
<tr><td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td>
<td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">optional, default: <code>1</code></td>
<td style="padding-right: 6px; padding-left: 6px; border-right: 1px solid #b8b8b8; white-space: nowrap;">read-only</td>
<td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>0</code>:</td>
<td style="padding-left: 12px;">Hopefully a track bike</td></tr><tr><td>&#160;</td>
<td>&#160;</td>
<td>&#160;</td>
<td style="text-align: right; padding-right: 6px; padding-left: 6px;"><code>1</code>:</td>
<td style="padding-left: 12px;">Always nice to have</td></tr>
</table><p>Does the bike have brakes?</p>

=end HTML

I<end>

A L<Moops> class defined like this:

    class My::MoopsClass using Moose {

        ...

        method advanced_method(Int $integer                        does doc("Just an integer\nmethod_doc|This method is advanced."),
                               ArrayRef[Str|Bool] $lots_of_stuff   does doc('It works with both types'),
                               Str :$name!                         does doc("What's the name"),
                               Int :$age                           does doc('The age of the thing') = 0,
                               Str :$pseudonym                     does doc('Incognito..')
                           --> Bool but assumed                    does doc('Did it succeed?')

        ) {
            return 1;
        }

        method less_advanced($stuff,
                             $another_thing                     does doc("Don't know what we get here"),
                             ArrayRef $the_remaining is slurpy  does doc('All the remaining')
        )  {
            return 1;
        }

        ...
    }

    =pod

    :splint classname My::MoopsClass

    :splint method advanced_method

    It needs lots of documentation.

    :splint method less_advanced

    =cut

Will render like this (to html):

I<begin>

=begin HTML

<h2 id="advanced_method">advanced_method</h2>



<p>This method is advanced.</p><table style="margin-bottom: 10px; margin-left: 10px; border-collapse: bollapse;" cellpadding="0" cellspacing="0">
<tr style="vertical-align: top;"><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">Positional parameters</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td></tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>$integer</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">required</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">Just an integer<br /></td>
</tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>$lots_of_stuff</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a>[ <a href="https://metacpan.org/pod/Types::Standard#Str">Str</a> | <a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a> ]</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">required</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">It works with both types<br /></td>
</tr>
<tr style="vertical-align: top;"><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">Named parameters</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td></tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>name =&gt; $value</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">required</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">What's the name</td>
</tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>age =&gt; $value</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#Int">Int</a></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">optional, default <code>= 0</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">The age of the thing</td>
</tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>pseudonym =&gt; $value</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#Str">Str</a></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">optional, <span style="color: #999;">no default</span></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">Incognito..</td>
</tr>
<tr style="vertical-align: top;"><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">Returns</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td></tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#Bool">Bool</a></td><td style="vertical-align: top; border-right: 1px solid #eee;  padding: 3px 6px; border-bottom: 1px solid #eee;">&#160;</td><td style="vertical-align: top; border-right: 1px solid #eee;  padding: 3px 6px; border-bottom: 1px solid #eee;">&#160;</td><td style="vertical-align: top; border-right: 1px solid #eee;  padding: 3px 6px; border-bottom: 1px solid #eee;">&#160;</td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">Did it succeed?</td>
</tr>
</table>

<p>It needs lots of documentation.</p>

<h2 id="less_advanced">less_advanced</h2>



<p></p><table style="margin-bottom: 10px; margin-left: 10px; border-collapse: bollapse;" cellpadding="0" cellspacing="0">
<tr style="vertical-align: top;"><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">Positional parameters</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td><td style="text-align: left; color: #444; background-color: #eee; font-weight: bold;">&#160;</td></tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>$stuff</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">required</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;"></td>
</tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>$another_thing</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">required</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  border-bottom: 1px solid #eee;"></td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">Don't know what we get here<br /></td>
</tr>
<tr style="vertical-align: top;">
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><code>$the_remaining</code></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;"><a href="https://metacpan.org/pod/Types::Standard#ArrayRef">ArrayRef</a></td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">required</td>
<td style="vertical-align: top; border-right: 1px solid #eee; white-space: nowrap;  padding: 3px 6px; border-bottom: 1px solid #eee;">slurpy</td>
<td style="padding: 3px 6px; vertical-align: top;  border-bottom: 1px solid #eee;">All the remaining<br /></td>
</tr>
</table>

=end HTML

I<end>

=head1 ATTRIBUTES

The following settings are available in C<weaver.ini>:

=head2 command_name

Default: C<:splint>

Defines the command used at the beginning of the line in pod.

=head2 attribute_renderer

Default: C<HTML=HtmlDefault, markdown=HtmlDefault>

Define which renderers to use. Comma separated list of pairs where the key defines the format in pod and the value defines the renderer (in the C<Pod::Elemental::Transformer::Splint::AttributeRenderer> namespace).

The default will render each attribute like this:

    =begin HTML

    <!-- attribute information -->

    =end HTML

    =begin markdown

    <!-- attribute information -->

    =end markdown

=head2 method_renderer

Default: C<HTML=HtmlDefault, markdown=HtmlDefault>

Similar to L</attribute_renderer> but for methods. This is currently only assumed to work for methods defined with L<Kavorka> or L<Moops>.

Method renderers are in the C<Pod::Elemental::Transformer::Splint::MethodRenderer> namespace.

=head2 type_libraries

Default: C<undef>

If you use L<Type::Tiny> based type libraries, the types are usually linked to the correct library. Under some circumstances it might be necessary to specify which library a certain type
belongs to.

It is a space separated list:

    type_libraries = Custom::Types=AType Types::Standard=Str,Int

=head2 default_type_library

Default: C<Types::Standard>

The default Type::Tiny based type library to link types to.

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Elemental-Transformer-Splint>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Elemental-Transformer-Splint>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
