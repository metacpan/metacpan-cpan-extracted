package OTRS::OPM::Analyzer::Role::TemplateCheck;

# ABSTRACT: Basic check for templates

use Moose::Role;
use HTML::Lint;

with 'OTRS::OPM::Analyzer::Role::Base';

sub check {
    my ( $self, $document ) = @_;
    
    return if $document->{filename} !~ m{ \.dtl \z }xms;
    
    my $content = $document->{content};
    
    my @results;
    push @results, $self->_template_uses_if( $content );
    push @results, $self->_template_uses_tab( $content );
    push @results, $self->_template_not_balanced_blocks( $content );
    push @results, $self->_template_html_lint_messages( $content );
    
    my $check_result = join "\n", @results;
    $check_result  ||= '';
    
    return $check_result;
}

sub _template_uses_if {
    my ( $self, $content ) = @_;
    
    my $error = $content =~ m{ ^ \s* (?![#]) \s* <!-- \s+ dtl:if }xms;
    
    return 'Templates uses <!-- dtl:if ... -->. This is deprecated.' if $error;
    return;
}

sub _template_uses_tab {
    my ( $self, $content ) = @_;
    
    my $error = $content =~ m{ \t }xms;
    
    return 'Templates uses hard tabs. Use 4 spaces instead.' if $error;
    return;
}

sub _template_html_lint_messages {
    my ( $self, $content ) = @_;
    
    my $lint = HTML::Lint->new;
    $lint->only_types( HTML::Lint::Error::STRUCTURE );
    $lint->parse( $content );
    
    my @errors;
    for my $error ( $lint->errors ) {
        my $string = $error->as_string;
        
        # we are not interested in "invalid character" errors as these
        # errors can occure when HTML::Lint cannot handle the character set
        # the template uses.
        next if $string =~ m{ Invalid \s+ character }xms;
        push @errors, $string;
    }
    
    my $error_string = join "\n", @errors;
    
    return $error_string if $error_string;
    return;
}

sub _template_not_balanced_blocks {
    my ( $self, $content ) = @_;
    
    my @blocks = $content =~ m{ <!-- \s+ dtl:([^\s]+) }xmsg;
    
    my %used_blocks;
    for my $block ( @blocks ) {
        $used_blocks{$block}++;
    }
    
    my @errors;
    for my $blockname ( keys %used_blocks ) {
        if ( $used_blocks{$blockname} % 2 != 0 ) {
            push @errors, "Not balanced use of dtl:$blockname";
        }
    }
    
    my $error_string = join "\n", @errors;
    
    return $error_string if $error_string;
    return;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Analyzer::Role::TemplateCheck - Basic check for templates

=head1 VERSION

version 0.06

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
