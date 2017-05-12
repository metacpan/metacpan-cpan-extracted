package Parse::Constructor::Arguments;
our $VERSION = '0.091570';


#ABSTRACT: Parse Moose constructor arguments using PPI
use Moose;
use PPI;
use MooseX::Types::Moose(':all');

BEGIN
{
    *DEBUG = sub () { 0 } unless defined *DEBUG{CODE};
}

has document =>
(
    is          => 'ro',
    isa         => 'PPI::Document',
    lazy_build  => 1,
);

has current =>
(
    is          => 'ro',
    isa         => 'PPI::Element',
    lazy        => 1,
    builder     => '_build_current',
    writer      => '_set_current',
);

has input   =>
(
    is          => 'ro',
    isa         => Str,
    required    => 1,
);

sub _build_current
{
    my $self = shift;
    # our first token should be significant
    my $token = $self->document->first_token;

    if($token->significant)
    {
        return $token;
    }
    
    while(1)
    {
        $token = $token->next_token;
        die "No more significant tokens in stream: '$token'" if not $token;
        return $token if $token->significant;
    }
}

sub _build_document
{
    my $self = shift;
    my $input = $self->input;
    my $document = PPI::Document->new(\$input);
    return $document;
}


    # states:
    # 0 - Looking for a Word or Literal to use as a key
    # 1 - Looking for a comma operator
    # 2 - Looking for a value
sub parse
{
    my $class = shift;
    my $str = shift;
    my $self = $class->new(input => $str);

    # grab the current token, which should be the first significant token
    my $token = $self->current;
    
    # what we are building
    my %data;

    # state related parsing variables
    my $key;
    my $state = 0;
    
    while(1)
    {
        if($state == 0)
        {
            if($token->isa('PPI::Token::Word'))
            {
                DEBUG && warn "Word Key: $token";
                $key = $token->content;
            }
            elsif($token->isa('PPI::Token::Quote::Single') or $token->isa('PPI::Token::Quote::Literal'))
            {
                DEBUG && warn "Quote Key: $token";
                $key = $token->literal;
            }
            else
            {
                die "Invalid state: Expected a Word or Literal but got '$token'";
            }
            
            $state++;
        }
        elsif($state == 1)
        {
            if($token->isa('PPI::Token::Operator') && $token->content =~ /,|=>/)
            {
                DEBUG && warn "Comma: $token";
            }
            else
            {
                die "Invalid state: Expected a Comma operator, but got '$token'";
            }
            
            $state++;
        }
        elsif($state == 2)
        {
            if($token->isa('PPI::Token::Quote::Single') or $token->isa('PPI::Token::Quote::Literal'))
            {
                DEBUG && warn "Quote Value: $token";
                $data{$key} = $token->literal;
            }
            elsif($token->isa('PPI::Token::Structure'))
            {
                my $content = $token->content;
                die "Unsupported structure '$content'"
                    if $content ne '[' and $content ne '{';

                DEBUG && warn 'Constructor: ' . $token->parent;
                $data{$key} = $self->process;
            }
            elsif($token->isa('PPI::Token::Number'))
            {
                DEBUG && warn "Number: $token";
                $data{$key} = $token->literal;
            }
            else
            {
                die "Invalid state: Expected Literal, Number or Structure, but got '$token'";
            }
            
            $state++;
            $key = undef;
        }
        elsif($state == 3)
        {
            if($token->isa('PPI::Token::Operator') && $token->content =~ /,|=>/)
            {
                DEBUG && warn "Comma: $token";
            }
            else
            {
                die "Invalid state: Expected a Comma operator, but got '$token'";
            }

            $state = 0;
        }
        
        if(my $t = $self->peek_next_token)
        {
            DEBUG && warn "Peeked and took $t";
            $token = $t;
            $self->_set_current($token);
        }
        else
        {
            DEBUG && warn "Peeked and there were no more tokens";
            last;
        }
    }

    return \%data;
}

sub process
{
    my $self = shift;
    my ($data, $applicator, $terminator, $word, $token);
    
    if($self->current->content eq '[')
    {
        DEBUG && warn "Processing Array...";
        $data = [];
        $terminator = ']';
        $applicator = sub { push(@{$_[0]}, $_[2]) };
    }
    else
    {
        DEBUG && warn "Processing Hash...";
        $data = {};
        $terminator = '}';
        $applicator = sub { $_[0]->{$_[1]} = $_[2] };
    }

    $token = $self->get_next_significant;

    while($token->content ne $terminator)
    {
        # words are stored until we know if they are a key or a value
        if($token->isa('PPI::Token::Word'))
        {
            DEBUG && warn "Process Word: $token";
            $word = $token->content;
            $token = $self->get_next_significant;
        }

        if($token->isa('PPI::Token::Number'))
        {
            DEBUG && warn "Process Number: $token";
            $applicator->($data, $word, $token->content);
            $word = undef;
        }
        elsif($token->isa('PPI::Token::Structure'))
        {
            DEBUG && warn "Process Structure: $token";
            $applicator->($data, $word, $self->process);
            $word = undef;
        }
        elsif($token->isa('PPI::Token::Quote::Single') || $token->isa('PPI::Token::Quote::Literal'))
        {
            DEBUG && warn "Process Quote: $token";
            if(!$word && $terminator eq '}')
            {
                DEBUG && warn "Process Hash Key Quote: $token";
                $word = $token->literal;
                $token = $self->get_next_significant;
                next;
            }

            $applicator->($data, $word, $token->literal);
            $word = undef;
        }
        elsif($token->isa('PPI::Token::QuoteLike::Words') and $terminator ne '}')
        {
            # This seems to be the only way to get the fuckin data from this token
            # which is completely retarded. Need to file a bug with PPI on this
            DEBUG && warn "Process QuoteLike Words: $token";
            
            my $operator = $token->{operator};
            my $separator = $token->{separator};
            my $content = $token->content;
            $content =~ s/$operator|$separator//g;
            
            $applicator->($data, undef, $_) for split(' ', $content);
        }
        elsif($token->isa('PPI::Token::Operator'))
        {
            DEBUG && warn "Process Comma: $token";
            if($token->content =~ /,|=>/)
            {
                $token = $self->get_next_significant;
                next;
            }
        }
        
        # now we process our words if they haven't been consumed
        DEBUG && warn "Process Add Word: $word" if $word;
        $applicator->($data, undef, $word) if $word;
        $word = undef;

        $token = $self->get_next_significant;
    }
    
    DEBUG && warn "Returning From Processing";
    return $data;
}

sub get_next_significant
{
    my $self = shift;
    my $token = $self->current;
    
    DEBUG && warn "Current: $token";
    while(1)
    {
        $token = $token->next_token;
        die 'No more significant tokens in stream: '. $self->document if not $token;
        
        if(!$token->significant)
        {
            next;
        }
        
        DEBUG && warn "Significant: $token";
        $self->_set_current($token);
        return $token;
    }
}

sub peek_next_token
{
    my $self = shift;
    my $token = $self->current;

    while(1)
    {
        $token = $token->next_token;
        return 0 if not $token;
        return $token if $token->significant;
    }
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Parse::Constructor::Arguments - Parse Moose constructor arguments using PPI

=head1 VERSION

version 0.091570

=head1 DESCRIPTION
Parse::Constructor::Arguments parses Moose-style constructor arguments into a 
usable data structure using PPI to accomplish the task. It exports nothing 
and the only public method is a class method: parse.

=head1 METHODS

=head2 parse(ClassName $class: Str $str)

This is a class method used for parsing constructor arguments. It takes a
string that will be used as the basis of the PPI::Document. Returns a hashref
where the keys are the named arguments and the values are the actual values to
those named arguments. (eg. q|foo => ['bar']| returns { foo => ['bar'] })

=head1 AUTHOR

  Nicholas Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Nicholas Perez.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut 



__END__
