package Output::Rewrite;

use warnings;
use strict;
use Carp;


tie *STDOUT, "Output::Rewrite";

my %rewrite_rule;
my $modifiers = 'g';


sub import {
	my $class = shift;
	my %fields = @_;
	if(ref $fields{rewrite_rule} eq 'HASH'){
		my %new_rewrite_rule = %{$fields{rewrite_rule}};
		rewrite_rule(%new_rewrite_rule);
	}
	if($fields{modifiers}){
		modifiers($fields{modifiers});
	}
}

sub modifiers {
	if(defined($_[0])){
		$modifiers = $_[0];
	}
	else{
		return $modifiers;
	}
}

sub rewrite_rule {
	my %new_rewrite_rule;
	if(@_ == 1){
		return $rewrite_rule{$_[0]};
	}
	else{
		%new_rewrite_rule = @_;
	}
	%rewrite_rule = (%rewrite_rule, %new_rewrite_rule);
}



sub _rewrite {
	my $self = shift;
	my $string = shift || return;
	
	while(my($from, $to) = each %rewrite_rule){
		if(ref $to eq 'CODE'){
			my $new_modifiers = $modifiers;
			$new_modifiers .= 'e' if($new_modifiers !~ /e/);
			eval "\$string =~ s/$from/&\$to()/$new_modifiers;";
		}
		else{
			#print STDERR "\$string =~ s/$from/$to/$modifiers;\n";
			eval "\$string =~ s/$from/$to/$modifiers;";
		}
		croak "Output::Rewrite Rewrite error:\n" . $@ if $@;
	}
	
	return $string;
}


sub TIEHANDLE {
	my $class = shift;
	my $form = shift;
	my $self;
	open($self, ">&STDOUT");
	#$$self->{hoge} = 'fuga';
	bless $self, $class;
}

sub PRINT {
	my $self = shift;
	no warnings;
	my $string = join('', @_);
	
	print $self $self->_rewrite($string);
}

sub PRINTF {
	my $self = shift;
	my $format = shift;
	$self->PRINT( $self->_rewrite( sprintf($format, @_) ) );
}

sub WRITE {
	my $self = shift;
	my $string = shift;
	my $length = shift || length $string;
	my $offset = shift || 0;
	
	syswrite($self, $self->_rewrite($string), $length, $offset);
}


=head1 NAME

Output::Rewrite - Rewrite your script output.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Output::Rewrite (
        rewrite_rule => {
            hoge => "fuga",
        }
    );
    print "hoge hogehoge\n";
    # fuga fugafuga
    
    
    
    use Output::Rewrite (
        rewrite_rule => {
            '(?<=\b)hoge(?=\b)' => "fuga",
        }
    );
    print "hoge hogehoge\n";
    # fuga hogehoge
    
    
    
    use Output::Rewrite (
        rewrite_rule => {
            '(\d)' => '$1!',
        }
    );
    print "1234 I love Marine Corps!\n";
    # 1!2!3!4! I love Marine Corps!
    
    
    use Output::Rewrite(
        modifiers => q/msgi/,
        rewrite_rule => {
            '(?-i)Sensitive' => 'SENSITIVE',
            'NoN sEnsItivE' => 'NON SENSITIVE',
        },
    );
    #or
    use Output::Rewrite;
    Output::Rewrite::rewrite_rule(
            '(?-i)Sensitive' => 'SENSITIVE',
            'NoN sEnsItivE' => 'NON SENSITIVE',
    );
    Output::Rewrite::modifiers('msgi');
    

=head1 DESCRIPTION

Output::Rewrite helps you to rewrite your script output.

When you print(or write, syswrite, printf) to STDOUT, Output::Rewrite hooks output and rewrite this.



Set rewrite rule(regex) and regex modifiers(i,g,m,s,x) when you load this module, 

    use Output::Rewrite (
        modifiers => 'ig',
        rewrite_rule => {
            'from' => 'to',
        }
    );

or with Output::Rewrite::rewrite_rule() and Output::Rewrite::modifiers().

    use Output::Rewrite;
    Output::Rewrite::modifiers('ig');
    Output::Rewrite::rewrite_rule(
        'from' => 'to',
    );

This module ties STDOUT so you must use carefully.

=head1 FUNCTIONS


=head2 rewrite_rule

Accessor for rewrite rule.

    Output::Rewrite::rewrite_rule(
        'from' => 'to',
        'from' => 'to',
    );


=head2 modifiers

Accessor for substitution modifiers.(i,g,m,s,x)
Default is 'g'.

    Output::Rewrite::modifiers('msgi');
    my $modifiers = Output::Rewrite::modifiers;

If you want to apply modifiers only one time, you can use (?imsx-imsx) instead of this.
For example:

    use Output::Rewrite(
        modifiers => q/msgi/, 
        rewrite_rule => {
            '(?-i)Sensitive' => 'SENSITIVE',
            'NoN sEnsItivE' => 'NON SENSITIVE',
        },
    );


=head1 AUTHOR

Hogeist, C<< <mahito at cpan.org> >>, L<http://www.ornithopter.jp/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-output-rewrite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Output-Rewrite>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Output::Rewrite

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Output-Rewrite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Output-Rewrite>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Output-Rewrite>

=item * Search CPAN

L<http://search.cpan.org/dist/Output-Rewrite>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hogeist, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Output::Rewrite
