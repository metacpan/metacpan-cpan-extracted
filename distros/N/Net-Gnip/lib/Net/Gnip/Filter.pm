package Net::Gnip::Filter;

use strict;
use base qw(Net::Gnip::Base);


=head1 NAME

Net::Gnip::Filter - a GNIP filter

=head1 SYNOPSIS

    my @rules  = ( { type => 'actor', value => 'joe' } );

    my $filter = Net::Gnip::Filter->new($name, $full_data, [@rules], %opts);
    my $name   = $filter->name;
    my $full   = $filter->full_data;
    my @rules  = $filter->rules;
    my %what   = $filter->what;

    $filter->what( url => $url );
    $filter->what( jid => $jid );

=head1 METHODS

=cut

=head2 new <name> <full data> <rule[s]> [opt[s]]

Create a new filter.

=cut
sub new {
    my $class = shift;
    my $name  = shift || die "You must pass in a name";
    my $full  = shift || die "You must pass in whether you want full data";
    my $rules = shift || die "You must pass in at least one rule";
    my %what  = @_;
    if (defined $what{postUrl} && defined $what{jid}) {
        die "You can only pass in a url or a jid option";
    }
    my %opts  = (
        name     => $name,
        fullData => $full,
        rules    => $rules,
        what     => \%what,
    );
    return bless \%opts, ref($class) || $class;
}

=head2 name [name]

Get or sets the name.

=cut
sub name { shift->_do('name', @_) }

=head2 full_data [full]

Get or set whether we want full data

=cut
sub full_data { shift->_do('fullData', @_) }

=head2 rules [rule[s]]

Get or set the rules. 

Rules should be hashrefs with a type key and value key.

The type key should be one of

    actor
    tag
    to
    regarding
    source

=cut
sub rules {
    my $self = shift;
    my @args;
    if (@_) {
        @args = [@_];
    }
    return @{$self->_do('rules', @args) || []};
}

=head2 what <type> <value>

Get or set what type is needed.

Type should be one of

    postUrl
    jid

=cut
sub what {
    my $self = shift;
    my @args;
    if (@args) {
        my $type  = shift;
        my $value = shift || "";
        @args = { $type => $value };
    }    
    return %{$self->_do('what', @args) || {}};
}

=head2 parse <xml>

Parse some xml into an activity.

=cut

sub parse {
    my $class  = shift;
    my $xml    = shift;
    my %opts   = @_;
    my $parser = $class->parser();
    my $doc    = $parser->parse_string($xml);
    my $elem   = $doc->documentElement();
    return $class->_from_element($elem, %opts);
}

sub _from_element {
    my $class = shift;
    my $elem  = shift;
    my %opts  = @_;
    foreach my $attr ($elem->attributes()) {
        my $name = $attr->name;
        $opts{$name} = $attr->value;
    }
    use Data::Dumper;
    my @rules;
    my %what;
    foreach my $child ($elem->childNodes) {
        my $name = $child->nodeName;
        if ('postUrl' eq $name || 'jid' eq $name) {
            $what{$name} = $child->firstChild->textContent;
        } elsif ('rule' eq $name) {
            my $rule;
            push @rules, $class->_parse_rule($child);
        }
    }
    return $class->new(delete $opts{name}, delete $opts{fullData}, [@rules], %what);
}

sub _parse_rule {
    my $self = shift;
    my $elem = shift;
    my $rule;
    $rule->{$_} = $elem->getAttribute($_) for qw(type value);
    return $rule;
}

=head2 as_xml

Return the activity as xml

=cut

sub as_xml {
    my $self       = shift;
    my $as_element = shift;
    my $element    = XML::LibXML::Element->new('filter');
    my $what       = delete $self->{what};
    my $rules      = delete $self->{rules};

    foreach my $key (keys %$self) {
        next if '_' eq substr($key, 0, 1);
        my $value = $self->{$key};
        $element->setAttribute($key, $value);
    }
    if (defined $what && defined [%$what]->[0]) {
        my $tmp = XML::LibXML::Element->new([%$what]->[0]);
        $tmp->appendTextNode([%$what]->[1]);     
        $element->addChild($tmp);
    }
    foreach my $rule (@$rules) {
        my $tmp = $self->_create_rule($rule);
        $element->addChild($tmp);
    }
    return ($as_element) ? $element : $element->toString(1);
}

sub _create_rule {
    my $self = shift;
    my $rule = shift;
    my $tmp = XML::LibXML::Element->new('rule');
    foreach my $key (keys %$rule) {
        $tmp->setAttribute($key, $rule->{$key});
    }
    return $tmp;
}

1;

