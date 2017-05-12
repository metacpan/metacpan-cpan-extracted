package Router::PathInfo::Controller;
use strict;
use warnings;

=head1 NAME

B<Router::PathInfo::Controller> provides a mapping PATH_INFO to controllers.

=head1 SYNOPSIS
    
    # create instance
    my $r = Router::PathInfo::Controller->new();
    
    # describe connect
    $r->add_rule(connect => '/foo/:enum(bar|baz)/:any', action => ['some','bar']);
    
    # prepare arguments (this action to prepare $env hidden from you in the module Router::PathInfo)
    my $env = {PATH_INFO => '/foo/baz/bar', REQUEST_METHOD => 'GET'};
    my @segment = split '/', $env->{PATH_INFO}, -1; 
    shift @segment;
    $env->{'psgix.tmp.RouterPathInfo'} = {
        segments => [@segment],
        depth => scalar @segment 
    };
    
    # match
    my $res = $r->match($env);  
	#  $res =  HASH(0x93d74d8)
	#   'action' => ARRAY(0x99294e8)
	#      0  'some'
	#      1  'bar'
	#   'segment' => ARRAY(0x93d8038)
	#      0  'baz'
	#      1  'bar'
	#   'type' => 'controller'

    # or $res may by undef

=head1 DESCRIPTION

C<Router::PathInfo::Controller> is used for matching sets of trees. 
Therefore, search matching is faster and more efficient, 
than a simple enumeration of regular expressions to search for a suitable result.

In the descriptions of 'C<connect>' by adding rules, you can use these tokens:

    :any                                 - match with any segment
    :re(...some regular expression...)   - match with the specified regular expression
    :enum(...|...)                       - match with a segment from the set

and sub-attribute for rules
    
    :name(...)

For example
    
    '/foo/:name(some_name)bar/:any'
    '/foo/:re(^\d{4}\w{4}$)/:name(my_token):any'
    '/:enum(foo|bar|baz)/:re(^\d{4}\w{4}$)/:any'
 
All descriptions of the segments have a certain weight. 
Thus, the description C<:enum> has the greatest weight, a description of C<:re> weighs even less. Weakest coincidence is C<:any>.

For all descriptions 'C<connect>' using these tokens in the match will be returned to a special key 'C<segment>' 
in which stores a list of all segments C<PATH_INFO> they are responsible.

An important point: description 'C<connect>' dominates over http method. Example:
    
    $r->add_rule(connect => '/foo/:any/baz', action => 'one', methods => ['GET','DELETE']);
    $r->add_rule(connect => '/foo/bar/:any', action => 'two');
    
    for '/foo/bar/baz' with GET -> 'two'

In C<action> you can pass any value: object, arrayref, hashref or a scalar.

=head1 METHODS

=cut

use namespace::autoclean;
use Carp;

my $http_methods = {
    GET     => 1,
    POST    => 1,
    PUT     => 1,
    OPTIONS => 1,
    DELETE  => 1,
    HEAD    => 1
};

=head2 new()

Simple constructor  

=cut
sub new {
    bless {
        rule => {},
        re_compile => {},
    }, shift;
}

=head2 add_rule(connect => $describe_connect, action => $action_token[, methods => $arrayref, match_callback => $code_ref])

Add your description to match.

'C<methods>' - arrayref of items GET, POST, PUT, OPTIONS, DELETE, HEAD

'C<match_callback>' - coderef is called after match found. It takes two arguments: a match found and heshref passed parameters (see method C<match>). 
Example:

    $r->add_rule(
        connect => '/foo/:enum(bar|baz)/:any', 
        action => ['any thing'], 
        methods => ['POST'], 
        match_callback => sub {
            my ($match, $env) = @_;
            
            if ($env->{...} == ..) {
                # $match->{action}->[0] eq 'any thing'
                return $match;
            } else {
                return {
                    type  => 'error',
                    code => 403,
                    desc  => 'blah-blah'   
                }; 
            }
        }
    );

=cut
sub add_rule {
    my ($self, %args) = @_;
    
    for ( ('connect', 'action') ) {
         unless ($args{$_}) {
             carp "missing '$_'";
             return;
         };
    }
    $args{methods} = $args{methods} ? [grep {$http_methods->{$_}} (ref $args{methods} eq 'ARRAY' ? @{$args{methods}} : $args{methods})] : [];
    my @methods =   $args{methods}->[0] ? @{$args{methods}} : keys %$http_methods;
    my $methods_weight = $#methods; 
    
    my $sub_after_match = $args{match_callback} if ref $args{match_callback} eq 'CODE';
    
    my @depth = split '/',$args{connect},-1;
    
    my $named_segment = {}; my $i = 0;
    
    my $res = [];
    for (@methods) {
        $self->{rule}->{$_}->{$#depth} ||= {};
        push @$res, $self->{rule}->{$_}->{$#depth};
    }
    
    (my $tmp = $args{connect}) =~ s!  
                (/)(?=/)                    | # double slash
                (/$)                        | # end slash
                /(:name\(["']?(.*?)["']?\))?:enum\(([^/]+)\)(?= $|/)   | # enum
                /(:name\(["']?(.*?)["']?\))?:re\(([^/]+)\)(?= $|/)     | # re
                /(:name\(["']?(.*?)["']?\))?(:any)(?= $|/)             | # any
                /(:name\(["']?(.*?)["']?\))?([^/]+)(?= $|/)              # eq
            !
                if ($1 or $2) {                    
                    $_->{exactly}->{''} ||= {} for @$res;
                    $res = [map {$_->{exactly}->{''}} @$res];
                } elsif ($5) {
                    my @val = split('\|',$5);
                    my @tmp;
                    for my $val (@val) {
                        for (@$res) {
                            $_->{exactly}->{$val} ||= {};
                            push @tmp, $_->{exactly}->{$val}; 
                        };
                    }
                    $res = [@tmp];
                    $named_segment->{$i} = $4 if $4;
                } elsif ($8) {
                    $self->{re_compile}->{$8} = qr{$8}s;
                    $_->{regexp}->{$8} ||= {} for @$res;
                    $res = [map {$_->{regexp}->{$8}} @$res];
                    $named_segment->{$i} = $7 if $7;
                } elsif ($11) {
                    $_->{default}->{''} ||= {} for @$res;
                    $res = [map {$_->{default}->{''}} @$res];
                    $named_segment->{$i} = $10 if $10;
                } elsif ($14) {
                    $_->{exactly}->{$14} ||= {} for @$res;
                    $res = [map {$_->{exactly}->{$14}} @$res];
                    $named_segment->{$i} = $13 if $13;
                } else {
                    # default as word
                    croak "cant't resolve connect '$args{connect}'"
                }
                $i++;
            !gex;
        
        for (@$res) {
            if (not $_->{match} or $_->{match}->[3] >= $methods_weight) {
                # set only if no match or a match for a more accurate description
                $_->{match} = [$args{action}, keys %$named_segment ? $named_segment : undef, $sub_after_match, $methods_weight];
            }
        }

    return 1;
}

sub _match {
    my ($self, $reserch, $size_el, @el) = @_;
    my $ret;
    my $not_exactly = 0;
    my $segment = shift @el;
    $size_el--;
    my $exactly = $reserch->{exactly}->{$segment};
    if (defined $exactly) {
        ($ret, $not_exactly) = $size_el ? $self->_match($exactly, $size_el, @el) : $exactly->{match};
        return ($ret, $not_exactly) if $ret; 
    };
    
    if ($reserch->{regexp}) {
        for (keys %{$reserch->{regexp}}) {
            if ($segment =~ $self->{re_compile}->{$_}) {
                ($ret) = $size_el ? $self->_match($reserch->{regexp}->{$_}, $size_el, @el) : $reserch->{regexp}->{$_}->{match};
                return ($ret, 1) if $ret;
            };
        }
    };
    
    if ($reserch->{default}) {
        ($ret) = $size_el ? $self->_match($reserch->{default}->{''}, $size_el, @el) : $reserch->{default}->{''}->{match};
        return ($ret, 1) if $ret;
    }
    
    return;
}

=head2 match({REQUEST_METHOD => ..., 'psgix.tmp.RouterPathInfo' => ...})

Search match. See SYNOPSIS.

If a match is found, it returns hashref:

    {
        type => 'controller',
        action => $action,
        name_segments => $arrayref
    }

Otherwise, undef. 

=cut
sub match {
	my $self = shift;
    my $env = shift;
    
    my $depth = $env->{'psgix.tmp.RouterPathInfo'}->{depth};
    
    my ($match, $not_exactly) = $self->_match(
        $self->{rule}->{$env->{REQUEST_METHOD}}->{$depth}, 
        $depth, 
        @{$env->{'psgix.tmp.RouterPathInfo'}->{segments}}
    );

    if ($match) {
        my $ret = {
            type => 'controller',
            action => $match->[0]
        };
        unless ($match->[1]) {
            $ret->{name_segments} = {};
        } else {
            $ret->{name_segments}->{$match->[1]->{$_}} = $env->{'psgix.tmp.RouterPathInfo'}->{segments}->[$_] for keys %{$match->[1]};
        }
        $ret->{_callback} = $match->[2] if $match->[2];
        return ($not_exactly, $ret);
    } else {
        return;
    }
    
#    if ($match) {
#    	my $ret = {
#            type => 'controller',
#            action => $match->[0],
#            segment => $match->[1] ? [map {$env->{'psgix.tmp.RouterPathInfo'}->{segments}->[$_]} @{$match->[1]}] : [] 
#        };
#    	if ($match->[2]) {
#    		return ($not_exactly, $match->[2]->($ret,$env)); 
#    	} else {
#    		return ($not_exactly, $ret);
#    	}
#    } else {
#    	return;
#    }
    
}

=head1 SEE ALSO

L<Router::PathInfo>, L<Router::PathInfo::Static>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
