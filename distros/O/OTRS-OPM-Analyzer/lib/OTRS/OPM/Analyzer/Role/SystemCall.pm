package OTRS::OPM::Analyzer::Role::SystemCall;

# ABSTRACT: check if the code does a system call

use Moose::Role;
use PPI;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ($self,$document) = @_;
    
    return if $document->{filename} !~ m{ \. (?:pl|pm|pod|t) \z }xms;
    
    my $ppi = PPI::Document->new( \$document->{content} );
    
    my @system_calls;
    
    # get all backtick-commands
    my $backticks = $ppi->find( 'PPI::Token::QuoteLike::Backtick' );
    push @system_calls, map{ $_->content }@{$backticks || []};
    
    # get all qx-commands 
    my $qx = $ppi->find( 'PPI::Token::QuoteLike::Command' );
    push @system_calls, map{ $_->content }@{$qx || []};
    
    my $words = $ppi->find( 'PPI::Token::Word' ) || [];
    
    my %dispatcher = (
        system => \&_system,
        open   => \&_open,
        exec   => \&_exec,
    );
    
    WORD:
    for my $word ( @{$words} ) {
        my $content = $word->content;
        my $sub     = $dispatcher{$content};
        
        next WORD if !$sub;
        
        # if it is a statement get content
        my $parent = $word->parent;
        if ( ref $parent eq 'PPI::Statement' ) {
            push @system_calls, $parent->content;
            next WORD;
        }
        
        # if not statement, check  next tokens -> list or word or quote -> I want it
        
        my $next_significant = $word->snext_sibling;
        my $ssibling_type    = ref $next_significant;
        
        next WORD if $ssibling_type !~ m{ \A
            PPI:: (?:
                Token::Word |
                Structure::List |
                Token::Quote::(?:Double|Single) |
                Token::QuoteLike::Words
            ) \z }xms;
            
        push @system_calls, $parent->content;
    }
    
    return join "\n", @system_calls;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::SystemCall - check if the code does a system call

=head1 VERSION

version 0.07

=head1 DESCRIPTION

It might be bad when OTRS add ons calls a third party program. Hence we check for it.

=head1 METHODS

=head2 check

See I<DESCRIPTION>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
