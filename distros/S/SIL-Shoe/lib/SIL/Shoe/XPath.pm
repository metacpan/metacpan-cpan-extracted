package SIL::Shoe::XPath;

use XML::XPath;
use XML::XPath::Parser;

sub parse_file
{
    my ($class, $fname, $twigs) = @_;
    my ($parser) = SIL::Shoe::XPath::XMLParser->new(
        'filename' => $fname);
    $parser->{'twigs'} = $twigs;
    my ($context) = $parser->parse;
    return $context;
}

package SIL::Shoe::XPath::XMLParser;

use XML::XPath::XMLParser;

@ISA = qw(XML::XPath::XMLParser);

sub parse_end
{
    my ($self, $expat) = @_;
    my ($t, $destroy, $curr);

    $curr = $self->{'current'};
    foreach $t (@{$self->{'twigs'}})
    {
        my ($res) = $t->[0]->evaluate($curr);
        if ($res->to_boolean->value)
        {
            $destroy ||= &{$t->[1]}($res, $t->[0]);
        }
    }       

    $self->{'current'} = $curr->getParentNode;
    $curr->dispose if ($destroy);
}


package XML::XPath;

=head3 find

Add the mode attribute set in new to be passed to the parser
before evaluation. This implies you must use the hash mode of
new.

=cut

sub find
{
    my ($self, $path, $context, $mode, $vars) = @_;

    if (!defined $context)
    { $context = $self->get_context; }

    if (!defined $context)
    {
        # Still no context? Need to parse...
        my $parser = XML::XPath::XMLParser->new(
                filename => $self->get_filename,
                xml => $self->get_xml,
                ioref => $self->get_ioref,
                parser => $self->get_parser,
                );
        $context = $parser->parse;
        $self->set_context($context);
#        warn "CONTEXT:\n", Data::Dumper->Dumpxs([$context], ['context']);
    }
    
    my $parsed_path = XML::XPath::Parser->new->parse($path);
#    warn "\n\nPATH: ", $parsed_path->as_string, "\n\n";

    $parsed_path->{'pp'}->set_mode($mode) if (defined $mode);
    foreach (keys %$vars)
    { $parsed_path->{'pp'}->set_var($_, XML::XPath::Literal->new($vars->{$_})); }
#    warn "evaluating path\n";
    return $parsed_path->evaluate($context);
}


package XML::XPath::Parser;

=head3 set_mode get_mode

Add functions for setting and getting the mode of parser evaluation

=cut 

sub set_mode { $_[0]->{'mode'} = $_[1]; }
sub get_mode { $_[0]->{'mode'}; }

%MYAXES = ( %AXES, 'exist' => 'element' );
$MYAXIS_NAME = '(' . join('|', keys %MYAXES) . ')::';

# include these functions as since need to replace AXIS_NAME with MYAXIS_NAME because
# we can't change the value of AXIS_NAME because it is use vars which is in effect
# my() and so we can't hack at the variables from here.

sub tokenize {
    my $self = shift;
    my $path = shift;
    study $path;
    
    my @tokens;
    
    debug("Parsing: $path\n");
    
    # Bug: We don't allow "'@' NodeType" which is in the grammar, but I think is just plain stupid.

    while($path =~ m/\G
        \s* # ignore all whitespace
        ( # tokens
            $LITERAL|
            $NUMBER_RE| # Match digits
            \.\.| # match parent
            \.| # match current
            ($AXIS_NAME)?$NODE_TYPE| # match tests
            processing-instruction|
            \@($NCWild|$QName|$QNWild)| # match attrib
            \$$QName| # match variable reference
            ($MYAXIS_NAME)?($NCWild|$QName|$QNWild)| # match NCName,NodeType,Axis::Test
            \!=|<=|\-|>=|\/\/|and|or|mod|div| # multi-char seps
            [,\+=\|<>\/\(\[\]\)]| # single char seps
            (?<!(\@|\(|\[))\*| # multiply operator rules (see xpath spec)
            (?<!::)\*|
            $ # match end of query
        )
        \s* # ignore all whitespace
        /gcxso) {

        my ($token) = ($1);

        if (length($token)) {
            debug("TOKEN: $token\n");
            push @tokens, $token;
        }
        
    }
    
    if (pos($path) < length($path)) {
        my $marker = ("." x (pos($path)-1));
        $path = substr($path, 0, pos($path) + 8) . "...";
        $path =~ s/\n/ /g;
        $path =~ s/\t/ /g;
        die "Query:\n",
            "$path\n",
            $marker, "^^^\n",
            "Invalid query somewhere around here (I think)\n";
    }
    
    return \@tokens;
}

sub Step {
    my ($self, $tokens) = @_;

    debug("in SUB\n");
    
    if (match($self, $tokens, '\\.')) {
        # self::node()
        return XML::XPath::Step->new($self, 'self', XML::XPath::Step::test_nt_node);
    }
    elsif (match($self, $tokens, '\\.\\.')) {
        # parent::node()
        return XML::XPath::Step->new($self, 'parent', XML::XPath::Step::test_nt_node);
    }
    else {
        # AxisSpecifier NodeTest Predicate(s?)
        my $token = $tokens->[$self->{_tokpos}];
        
        debug("SUB: Checking $token\n");
        
        my $step;
        if ($token eq 'processing-instruction') {
            $self->{_tokpos}++;
            match($self, $tokens, '\\(', 1);
            match($self, $tokens, $LITERAL);
            $self->{_curr_match} =~ /^["'](.*)['"]$/;
            $step = XML::XPath::Step->new($self, 'child',
                                    XML::XPath::Step::test_nt_pi,
                        XML::XPath::Literal->new($1));
            match($self, $tokens, '\\)', 1);
        }
        elsif ($token =~ /^\@($NCWild|$QName|$QNWild)$/o) {
            $self->{_tokpos}++;
                        if ($token eq '@*') {
                            $step = XML::XPath::Step->new($self,
                                    'attribute',
                                    XML::XPath::Step::test_attr_any,
                                    '*');
                        }
                        elsif ($token =~ /^\@($NCName):\*$/o) {
                            $step = XML::XPath::Step->new($self,
                                    'attribute',
                                    XML::XPath::Step::test_attr_ncwild,
                                    $1);
                        }
                        elsif ($token =~ /^\@($QName)$/o) {
                            $step = XML::XPath::Step->new($self,
                                    'attribute',
                                    XML::XPath::Step::test_attr_qname,
                                    $1);
                        }
        }
        elsif ($token =~ /^($NCName):\*$/o) { # ns:*
            $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child', 
                                XML::XPath::Step::test_ncwild,
                                $1);
        }
        elsif ($token =~ /^$QNWild$/o) { # *
            $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child', 
                                XML::XPath::Step::test_any,
                                $token);
        }
        elsif ($token =~ /^$QName$/o) { # name:name
            $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child', 
                                XML::XPath::Step::test_qname,
                                $token);
        }
        elsif ($token eq 'comment()') {
                    $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child',
                            XML::XPath::Step::test_nt_comment);
        }
        elsif ($token eq 'text()') {
            $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child',
                    XML::XPath::Step::test_nt_text);
        }
        elsif ($token eq 'node()') {
            $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child',
                    XML::XPath::Step::test_nt_node);
        }
        elsif ($token eq 'processing-instruction()') {
            $self->{_tokpos}++;
            $step = XML::XPath::Step->new($self, 'child',
                    XML::XPath::Step::test_nt_pi);
        }
        elsif ($token =~ /^$MYAXIS_NAME($NCWild|$QName|$QNWild|$NODE_TYPE)$/o) {
                    my $axis = $1;
                    $self->{_tokpos}++;
                    $token = $2;
            if ($token eq 'processing-instruction') {
                match($self, $tokens, '\\(', 1);
                match($self, $tokens, $LITERAL);
                $self->{_curr_match} =~ /^["'](.*)['"]$/;
                $step = XML::XPath::Step->new($self, $axis,
                                        XML::XPath::Step::test_nt_pi,
                            XML::XPath::Literal->new($1));
                match($self, $tokens, '\\)', 1);
            }
            elsif ($token =~ /^($NCName):\*$/o) { # ns:*
                $step = XML::XPath::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ? 
                                    XML::XPath::Step::test_attr_ncwild
                                        :
                                    XML::XPath::Step::test_ncwild),
                                    $1);
            }
            elsif ($token =~ /^$QNWild$/o) { # *
                $step = XML::XPath::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ?
                                    XML::XPath::Step::test_attr_any
                                        :
                                    XML::XPath::Step::test_any),
                                    $token);
            }
            elsif ($token =~ /^$QName$/o) { # name:name
                $step = XML::XPath::Step->new($self, $axis, 
                                    (($axis eq 'attribute') ?
                                    XML::XPath::Step::test_attr_qname
                                        :
                                    XML::XPath::Step::test_qname),
                                    $token);
            }
            elsif ($token eq 'comment()') {
                $step = XML::XPath::Step->new($self, $axis,
                                XML::XPath::Step::test_nt_comment);
            }
            elsif ($token eq 'text()') {
                $step = XML::XPath::Step->new($self, $axis,
                        XML::XPath::Step::test_nt_text);
            }
            elsif ($token eq 'node()') {
                $step = XML::XPath::Step->new($self, $axis,
                        XML::XPath::Step::test_nt_node);
            }
            elsif ($token eq 'processing-instruction()') {
                $step = XML::XPath::Step->new($self, $axis,
                        XML::XPath::Step::test_nt_pi);
            }
            else {
                die "Shouldn't get here";
            }
        }
        else {
            die "token $token doesn't match format of a 'Step'\n";
        }
        
        while (match($self, $tokens, '\\[')) {
            push @{$step->{predicates}}, Expr($self, $tokens);
            match($self, $tokens, '\\]', 1);
        }
        
        return $step;
    }
}

sub is_step {
    my ($self, $tokens) = @_;
    
    my $token = $tokens->[$self->{_tokpos}];
    
    return unless defined $token;
        
    debug("SUB: Checking if '$token' is a step\n");
    
        local $^W;
        
    if ($token eq 'processing-instruction') {
        return 1;
    }
    elsif ($token =~ /^\@($NCWild|$QName|$QNWild)$/o) {
        return 1;
    }
    elsif ($token =~ /^($NCWild|$QName|$QNWild)$/o && $tokens->[$self->{_tokpos}+1] ne '(') {
        return 1;
    }
    elsif ($token =~ /^$NODE_TYPE$/o) {
        return 1;
    }
    elsif ($token =~ /^$MYAXIS_NAME($NCWild|$QName|$QNWild|$NODE_TYPE)$/o) {
        return 1;
    }
    
    debug("SUB: '$token' not a step\n");

    return;
}

# end of nearly redundant code copying, sigh.

package XML::XPath::Step;

sub evaluate_node
{
    my $self = shift;
    my $context = shift;
    my $method = $self->{axis_method};    
    my $results = XML::XPath::NodeSet->new();

    no strict 'refs';
    eval
    { $method->($self, $context, $results); };
    if ($@) 
    { die "axis $method not implemented [$@]\n"; }
    
    foreach my $predicate (@{$self->{predicates}})
    { $results = $self->filter_by_predicate($results, $predicate); }
    $self->{'pp'}->set_mode('create') if ($self->{'pp'}->get_mode eq 'create_test');
    
    return $results;
}

sub filter_by_predicate {
    my $self = shift;
    my ($nodeset, $predicate) = @_;
    
    # See spec section 2.4, paragraphs 2 & 3:
    # For each node in the node-set to be filtered, the predicate Expr
    # is evaluated with that node as the context node, with the number
    # of nodes in the node set as the context size, and with the
    # proximity position of the node in the node set with respect to
    # the axis as the context position.
    
    if (!ref($nodeset)) { # use ref because nodeset has a bool context
        die "No nodeset!!!";
    }
    
#    warn "Filter by predicate: $predicate\n";
    
    my $newset = XML::XPath::NodeSet->new();
    
    for(my $i = 1; $i <= $nodeset->size; $i++) {
        my ($node) = $nodeset->get_node($i);
        # set context set each time 'cos a loc-path in the expr could change it
        $self->{pp}->set_context_set($nodeset);
        $self->{pp}->set_context_pos($i);
        my $result = $predicate->evaluate($node);

        foreach my $n ($node->getAttributes)
        {
            my ($k, $v);
            if ($n->getNodeVars)
            {
                while (($k, $v) = each %{$n->getNodeVars})
                { $node->setNodeVar($k, $v); }
            }
        }

        if ($result->isa('XML::XPath::Boolean')) {
            if ($result->value) {
                $newset->push($node);
            }
        }
        elsif ($result->isa('XML::XPath::Number')) {
            if ($result->value == $i) {
                $newset->push($node);
            }
        }
        elsif ($result->isa('XML::XPath::NodeSet') && $result->to_boolean->value) {
            foreach my $n ($result->get_nodelist())
            {
                my ($k, $v, $n1);
                foreach $n1 ($n, $n->getAttributes)
                {
                    next unless (defined $n1->getNodeVars);
                    while (($k, $v) = each %{$n1->getNodeVars})
                    { $node->setNodeVar($k, $v); }
                }
            }
            $newset->push($node);
        }
        elsif ($result->isa('XML::XPath::Node') && $result->to_boolean->value) {
            foreach my $n ($result, $result->getAttributes)
            {
                my ($k, $v);
                if (defined $n->getNodeVars)
                {
                    while (($k, $v) = each %{$n->getNodeVars})
                    { $node->setNodeVar($k, $v); }
                }
            }
            $newset->push($node);
        }
        elsif ($result->to_boolean->value) {
            $newset->push($node);
        }
    }
    
    return $newset;
}

=head3 axis_child

If creating, add a child element if the element type is NCName.

=cut

sub axis_child
{
    my ($self, $context, $results) = @_;

    if ($self->{'pp'}->get_mode eq 'create' && $self->{'test'} == XML::XPath::Step::test_qname)
    {
        my ($pref, $key) = split(':', $self->{'literal'});

        if (!$key)
        {
            $key = $pref;
            $pref = '';
        }
        my ($newnode) = XML::XPath::Node::Element->new($key, $pref);
        my ($tempres) = XML::XPath::NodeSet->new;
        $context->appendChild($newnode);
        $results->push($newnode);
    }
    else
    {
        foreach my $node (@{$context->getChildNodes})
        {
            if (node_test($self, $node))
            { $results->push($node); }
        }
    }
}

=head3 axis_exist

Add a new axis: exist::node. Which is identical to child::node unless creating in which case
only test do not create any nodes for this step

=cut

sub axis_exist
{
    my ($self, $context, $results) = @_;
    my ($mode);

    if ($self->{'pp'}->get_mode eq 'create')
    { $self->{'pp'}->set_mode('create_test'); }

    foreach my $node (@{$context->getChildNodes})
    {
        if (node_test($self, $node))
        { $results->push($node); }
    }

    if ($self->{'pp'}->get_mode eq 'create_test')
    { $self->{'pp'}->set_mode('create'); }
}


=head3 axis_attribute

If creating, add an attribute element if there is no attribute of that name

=cut

sub axis_attribute
{
    my $self = shift;
    my ($context, $results) = @_;
    my ($nonempty);
    
    foreach my $attrib (@{$context->getAttributes})
    {
        if ($self->test_attribute($attrib))
        { 
            $results->push($attrib);
            $nonempty = 1;
        }
    }

    if (!$nonempty && $self->{'pp'}->get_mode eq 'create')
    {
        my ($pref, $key) = split(':', $self->{'literal'});
        if (!$key)
        {
            $key = $pref;
            $pref = '';
        }
        my ($newnode) = XML::XPath::Node::Attribute->new($key, undef, $pref);
        $context->appendAttribute($newnode);
        $results->push($newnode);
    }
}


package XML::XPath::Expr;

=head3 op_or

Change semantics so returns the result of the first true evaluation. Implied sequence
point remains

=cut

sub op_or
{
    my ($node, $lhs, $rhs) = @_;
    my ($res) = $lhs->evaluate($node);

    if ($res->to_boolean->value)
    { return $res; }
    else
    { return $rhs->evaluate($node); }
}

=head3 op_and

Change semantics to return false or last true evaluation result. Implied sequence
point remains.

TODO: When collecting variables, filter rhs result based on unification with lhs variables

=cut

sub op_and
{
    my ($node, $lhs, $rhs) = @_;
    my ($left, $right);

    $left = $lhs->evaluate($node);
    if( !$left->to_boolean->value )
    { return XML::XPath::Boolean->False; }
    else
    {
        $right = $rhs->evaluate($node);
        if ($right->to_boolean->value && $lhs->{'pp'}->get_mode eq 'collect')
        { $right = unify_vars($right, $left); }
        if ($right->to_boolean->value)
        { return $right; }
        else
        { return XML::XPath::Bolean->False; }
    }
}


sub unify_vars
{
    my ($left, $right) = @_;
    my ($i);
    
    if ($left->isa('XML::XPath::NodeSet'))
    {
        for ($i = 0; $i < scalar @{$left}; $i++)
        {
            unless (unify_node($left->[$i], $right))
            {
                splice(@{$left}, $i, 1);
                $i--;
            }
        }
        if ($left->size < 1)
        { return undef; }
        return $left;
    }
    elsif ($left->isa('XML::XPath::Node'))
    { return unify_node($left, $right); }
    else
    { return $left; }
}

sub unify_node
{
    my ($left, $right) = @_;
    my ($n);
    
    if ($right->isa('XML::XPath::NodeSet'))
    {
        foreach $n ($right->get_nodelist())
        {
            next unless ($n->isa('XML::XPath::Node'));
            return $left if (unify($left, $n));
        }
    }
    elsif ($right->isa('XML::XPath::Node'))
    { return unify($left, $right); }
    else
    { return $left; }
}

sub unify
{
    my ($left, $right) = @_;
    my ($n, $k, $v);
    
#    foreach $n ($right->isa('XML::XPath::Node::Attribute') ? $right : ($right, $right->get_attributes))
    $n = $right;
    {
        while (($k, $v) = each %{$n->getNodeVars})
        {
            if (defined $left->getNodeVars->{$k} and $left->getNodeVars->{$k}->string_value ne $v->string_value)
            { return undef; }
        }
        while (($k, $v) = each %{$n->getNodeVars})
        { $left->setNodeVar($k, $v); }
    }
    return $left;
}
           

=head3 op_equals

Add creation and collection semantics

=cut

sub op_equals
{
    my ($node, $lhs, $rhs) = @_;
    my ($lh_results) = $lhs->evaluate($node);
    my ($rh_results);
    if ($lhs->{'pp'}->get_mode eq 'collect'
        && !$rhs->{'op'} 
        && $rhs->{'lhs'}->isa('XML::XPath::Variable'))
    {
        if ($lh_results->isa('XML::XPath::Node'))
        { $lh_results->setNodeVar($rhs->{'lhs'}{'name'}, $lh_results); }
        elsif ($lh_results->isa('XML::XPath::NodeSet'))
        {
            foreach my $n ($lh_results->get_nodelist)
            { $n->setNodeVar($rhs->{'lhs'}{'name'}, $n); }
        }
        return $lh_results;
    }
    else
    { $rh_results = $rhs->evaluate($node); }

    return XML::XPath::Boolean->False unless (ref $lh_results && ref $rh_results);

    if ($lh_results->isa('XML::XPath::NodeSet') &&
            $rh_results->isa('XML::XPath::NodeSet'))
    {
        my ($rhval) = ($rh_results->get_nodelist)[0] ? ($rh_results->get_nodelist)[0]->string_value : '';
        # True if and only if there is a node in the
        # first set and a node in the second set such
        # that the result of performing the comparison
        # on the string-values of the two nodes is true.
        for ($i = 0; $i < $lh_results->size; $i++)
        {
            my ($lhnode) = $lh_results->get_node($i + 1);
            if ($lhs->{'pp'}->get_mode eq 'create')
            {
                my ($lhval) = $lhnode->string_value;
                if (!$lhval)
                { $lhnode->setValue($rhval); }
                elsif ($lhval ne $rhval)
                { splice (@{$lh_results}, $i--, 1); }
            }
            else
            {
                foreach my $rhnode ($rh_results->get_nodelist)
                {
                    if ($lhnode->string_value eq $rhnode->string_value)
                    { return XML::XPath::Boolean->True; }
                }
            }
        }
        if ($lhs->{'pp'}->get_mode eq 'create')
        { return $lh_results; }
        else
        { return XML::XPath::Boolean->False; }
    }
    elsif ($lhs->{'pp'}->get_mode eq 'create' && $lh_results->isa('XML::XPath::NodeSet'))
    {
        my ($rhval) = $rh_results->string_value;
        for ($i = 0; $i < $lh_results->size; $i++)
        {
            my ($lhnode) = $lh_results->get_node($i + 1);
            my ($lhval) = $lhnode->string_value;

            if ($lhnode->isa('XML::XPath::Node::Element') || $lhnode->isa('XML::XPath::Node::Attribute'))
            {
                if (!$lhval)
                { $lhnode->setValue($rhval); }
                elsif ($lhval ne $rhval)
                { splice (@{$lh_results}, $i--, 1); }
            }
        }
        return $lh_results;
    }
    elsif ($lh_results->isa('XML::XPath::NodeSet') || $rh_results->isa('XML::XPath::NodeSet'))
    {
        my ($nodeset, $other);
        if ($lh_results->isa('XML::XPath::NodeSet')) {
            $nodeset = $lh_results;
            $other = $rh_results;
        }
        else {
            $nodeset = $rh_results;
            $other = $lh_results;
        }
        # True if and only if there is a node in the
        # nodeset such that the result of performing
        # the comparison on <type>(string_value($node))
        # is true.
        if ($other->isa('XML::XPath::Number')) {
            foreach my $node ($nodeset->get_nodelist) {
                if ($node->string_value == $other->value) {
                    return XML::XPath::Boolean->True;
                }
            }
        }
        elsif ($other->isa('XML::XPath::Literal')) {
            foreach my $node ($nodeset->get_nodelist) {
                if ($node->string_value eq $other->value) {
                    return XML::XPath::Boolean->True;
                }
            }
        }
        elsif ($other->isa('XML::XPath::Boolean')) {
            if ($nodeset->to_boolean->value == $other->value) {
                return XML::XPath::Boolean->True;
            }
        }

        return XML::XPath::Boolean->False;
    }
    elsif ($lh_results->isa('XML::XPath::Boolean') || $rh_results->isa('XML::XPath::Boolean'))
    {
        # if either is a boolean
        if ($lh_results->to_boolean->value == $rh_results->to_boolean->value) {
            return XML::XPath::Boolean->True;
        }
        return XML::XPath::Boolean->False;
    }
    elsif ($lh_results->isa('XML::XPath::Number') || $rh_results->isa('XML::XPath::Number'))
    {
        # if either is a number
        local $^W; # 'number' might result in undef
        if ($lh_results->to_number->value == $rh_results->to_number->value) {
            return XML::XPath::Boolean->True;
        }
        return XML::XPath::Boolean->False;
    }
    elsif ($lh_results->to_literal->value eq $rh_results->to_literal->value)
    { return XML::XPath::Boolean->True; }
    else
    { return XML::XPath::Boolean->False; }
}

sub op_nequals {
    my ($node, $lhs, $rhs) = @_;
    if (op_equals($node, $lhs, $rhs)->to_boolean->value) {
        return XML::XPath::Boolean->False;
    }
    return XML::XPath::Boolean->True;
}

package XML::XPath::Function;

use Text::LangTag;

=head3 evaluate

When creating, if a node occurs in a function, it is not created

=cut

sub evaluate
{
    my $self = shift;
    my $node = shift;
    my ($res);
    if ($node->isa('XML::XPath::NodeSet')) {
        $node = $node->get_node(1);
    }
    my @params;
    $self->{'pp'}->set_mode('create_test') if ($self->{'pp'}->get_mode eq 'create');
    $self->{'pp'}->set_mode('collect_test') if ($self->{'pp'}->get_mode eq 'collect');
    foreach my $param (@{$self->{params}}) {
        my $results = $param->evaluate($node);
        push @params, $results;
    }
    $self->{'pp'}->set_mode('create') if ($self->{'pp'}->get_mode eq 'create_test');
    $res = $self->_execute($self->{name}, $node, @params);
    $self->{'pp'}->set_mode('collect') if ($self->{'pp'}->get_mode eq 'collect_test');
    return $res;
}

=head3 ss(lang_tag, script, [suppress])

Creates a new language tag from the given language tag, the script to apply to the
language and an optional script to suppress

=cut

sub ss
{
    my ($self, $node, @params) = @_;

    die "ss: wrong number of parameters, requires 2-3" if (@params < 2 || @params > 3);

    my ($lang) = Text::LangTag->parse($params[0]->string_value);
    my ($script) = Text::LangTag->parse($params[1]->string_value);
    my ($suppress) = Text::LangTag->parse($params[2]->string_value) if (@params == 3);
    $lang->suppress($script, $suppress);
    return XML::XPath::Literal->new($lang->to_string);
}

=head3 os(first, second)

Effectively returns first || second, i.e. returns first if it is defined else
returns the second. (or_string).

=cut

sub os
{
    my ($self, $node, @params) = @_;
    
    die "os: wrong number of parameters, requires 2" if (@params != 2);
    return XML::XPath::Literal->new(defined $params[0] && $params[0]->string_value || defined $params[1] && $params[1]->string_value);
}

package XML::XPath::Node::ElementImpl;

use XML::XPath::Node qw(:node_keys);

=head3 setNodeValue

Set the first text node to the given value and delete all others. Insert
a text node as first child node if none exists.

=cut

sub setNodeValue
{
    my ($self, $value) = @_;
    my ($kid, $stored);

    foreach my $kid (@{$self->[node_children]})
    {
        if ($kid->getNodeType == TEXT_NODE)
        {
            if ($stored)
            { $self->removeChild($kid); }
            else
            {
                $stored = 1;
                $kid->setNodeValue($value);
            }
        }
    }
    unless ($stored)
    {
        my ($newnode) = XML::XPath::Node::Text->new($value);
        if (@{$self->[node_children]})
        { $self->insertBefore($newnode, $self->[node_children][0]); }
        else
        { $self->appendChild($newnode); }
    }
}

=head3 toString

Add indentation support

=cut

sub toString {
    my $self = shift;
    my $norecurse = shift;
    my $indent = shift;
    my $increase = shift || 2;
    my $string = '';

    if (!$self->[node_name])            # root node
    { return join('', map { $_->toString($norecurse, $indent, $increase) } @{$self->[node_children]}); }

    $string .= "\n" . $indent . "<" . $self->[node_name];
    $string .= join('', map { $_->toString } @{$self->[node_namespaces]});
    $string .= join('', map { $_->toString } @{$self->[node_attribs]});
    
    if (@{$self->[node_children]})
    {
        $string .= ">";
        if (!$norecurse) 
        { $string .= join('', map { $_->toString($norecurse, $indent . (" " x $increase), $increase) } @{$self->[node_children]}); }
        $string =~ s/(>)$/"$1\n$indent"/oe;
        $string .= "</" . $self->[node_name] . ">";
    }
    else 
    { $string .= " />"; }
    
    return $string;
}

package XML::XPath::NodeImpl;


sub setNodeVar
{
    my ($self, $key, $value) = @_;

    $self->[9]{$key} = $value;
}

sub getNodeVars
{
    my ($self) = @_;

    return $self->[9];
}


1;
