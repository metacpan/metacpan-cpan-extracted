package Mock::Person::US;
{
  $Mock::Person::US::VERSION = '1.1.0';
}

# ENCODING: UTF-8



use strict;
use warnings;
use utf8;

my @first_male = qw(
james
john
robert
michael
william
david
richard
charles
joseph
thomas
christopher
daniel
paul
mark
donald
george
kenneth
steven
edward
brian
ronald
anthony
kevin
jason
matthew
gary
timothy
josé
larry
jeffrey
frank
scott
eric
stephen
andrew
raymond
gregory
joshua
jerry
dennis
walter
patrick
peter
harold
douglas
henry
carl
arthur
ryan
roger
joe
juan
jack
albert
jonathan
justin
terry
gerald
keith
samuel
willie
ralph
lawrence
nicholas
roy
benjamin
bruce
brandon
adam
harry
fred
wayne
billy
steve
louis
jeremy
aaron
randy
howard
eugene
carlos
russell
bobby
victor
martin
ernest
phillip
todd
jesse
craig
alan
shawn
clarence
sean
philip
chris
johnny
earl
jimmy
antonio
);

my @first_female = qw(
mary
patricia
linda
barbara
elizabeth
jennifer
maria
susan
margaret
dorothy
lisa
nancy
karen
betty
helen
sandra
donna
carol
ruth
sharon
michelle
laura
sarah
kimberly
deborah
jessica
shirley
cynthia
angela
melissa
brenda
amy
anna
rebecca
virginia
kathleen
pamela
martha
debra
amanda
stephanie
carolyn
christine
marie
janet
catherine
frances
ann
joyce
diane
alice
julie
heather
teresa
doris
gloria
evelyn
jean
cheryl
mildred
katherine
joan
ashley
judith
rose
janice
kelly
nicole
judy
christina
kathy
theresa
beverly
denise
tammy
irene
jane
lori
rachel
marilyn
andrea
kathryn
louise
sara
anne
jacqueline
wanda
bonnie
julia
ruby
lois
tina
phyllis
norma
paula
diana
annie
lillian
emily
robin
);

my @last_name = qw(
smith
johnson
williams
jones
brown
davis
miller
wilson
moore
taylor
anderson
thomas
jackson
white
harris
martin
thompson
garcía
martínez
robinson
clark
rodríguez
lewis
lee
walker
hall
allen
young
hernández
king
wright
lópez
hill
scott
green
adams
baker
gonzález
nelson
carter
mitchell
pérez
roberts
turner
phillips
campbell
parker
evans
edwards
collins
stewart
sánchez
morris
rogers
reed
cook
morgan
bell
murphy
bailey
rivera
cooper
richardson
cox
howard
ward
torres
peterson
gray
ramírez
james
watson
brooks
kelly
sanders
price
bennett
wood
barnes
ross
henderson
coleman
jenkins
perry
powell
long
patterson
hughes
flores
washington
butler
simmons
foster
gonzales
bryant
alexander
russell
griffin
díaz
hayes
);


sub name {
    my ($sex) = @_;
    # First Middle Last
    if ($sex eq "female") {
        return join(' ', map { ucfirst $_ }
            first_female(), first_female(), last_name());
    }
    else {
        return join(' ', map { ucfirst $_ }
            first_male(), first_male(), last_name());
    }
}


sub first_male {
     return ucfirst($first_male[rand @first_male]);
}


sub first_female {
     return ucfirst($first_female[rand @first_female]);
}


sub last_name {
     return ucfirst($last_name[rand @last_name]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Person::US

=head1 VERSION

version 1.1.0

=head1 DESCRIPTION

Data for this module was found on these pages:

=over

=item B<Last names>

L<http://names.mongabay.com/most_common_surnames.htm>

=item B<First names>

L<http://names.mongabay.com/female_names.htm> and
L<http://names.mongabay.com/male_names.htm>

=back

=head1 NAME

Mock::Person::US - Support module to generate American names

=head1 FUNCTIONS

=head2 name

Receives scalar with sex of the person ('male' or 'female') and returns
scalar with generated name.

=head2 first_male

Returns random first name of male person.

=head2 first_female

Returns random first name of female person.

=head2 last_name

Returns random last name of male or female person.

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
