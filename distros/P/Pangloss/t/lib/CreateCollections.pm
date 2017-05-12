package CreateCollections;

use Pangloss::Category;
use Pangloss::Categories;

use Pangloss::Concept;
use Pangloss::Concepts;

use Pangloss::Language;
use Pangloss::Languages;

use Pangloss::Term;
use Pangloss::Terms;

use Pangloss::User;
use Pangloss::Users;

sub create_users {
my $users = new Pangloss::Users()
  ->add(
	Pangloss::User->new
	  ->id('admin')
	  ->name('admin user')
	  ->creator('admin')
	  ->privileges( Pangloss::User::Privileges->new->admin(1) ),
	Pangloss::User->new
	  ->id('test')
	  ->name('test user')
	  ->creator('admin')
	  ->privileges( Pangloss::User::Privileges->new->add_categories(1) ),
	Pangloss::User->new->id('user 1'),
	Pangloss::User->new->id('user 2'),
	Pangloss::User->new->id('user 3'),
	Pangloss::User->new->id('user A'),
	Pangloss::User->new->id('user B'),
	Pangloss::User->new->id('user C'),
       );
}

sub create_languages {
my $languages = new Pangloss::Languages()
  ->add(
	Pangloss::Language->new
	  ->iso_code('te')
	  ->name('test language')
	  ->creator('admin'),
	Pangloss::Language->new
	  ->iso_code('et')
	  ->name('tset')
	  ->notes('test backwards')
	  ->creator('admin'),
       );
}

sub create_categories {
my $categories = new Pangloss::Categories()
  ->add(
	Pangloss::Category->new
	  ->name('test category')
	  ->creator('test'),
	Pangloss::Category->new->name('category 1'),
	Pangloss::Category->new->name('category 2'),
	Pangloss::Category->new->name('category 3'),
       );
}

sub create_concepts {
my $concepts = new Pangloss::Concepts()
  ->add(
	Pangloss::Concept->new
	  ->name('concept 1')
	  ->date(1)
	  ->creator('test'),
	Pangloss::Concept->new
	  ->name('concept 2')
	  ->date(2)
	  ->category('category 2')
	  ->creator('test'),
	Pangloss::Concept->new
	  ->name('concept 3')
	  ->date(3)
	  ->category('category 3')
	  ->creator('test'),
       );
}

sub create_terms {
my $terms = new Pangloss::Terms()
  ->add(
	Pangloss::Term->new
	  ->name('term 1')
	  ->date(1)
	  ->concept('concept 1')
	  ->language('te')
	  ->creator('user 1')
	  ->status(
		   Pangloss::Term::Status->new
		     ->pending
		     ->date( 2 )
		     ->creator( 'user A' )
		  ),
	Pangloss::Term->new
	  ->name('term 2')
	  ->date(2)
	  ->concept('concept 2')
	  ->language('et')
	  ->creator('user 2')
	  ->status(
		   Pangloss::Term::Status->new
		     ->approved
		     ->date( 3 )
		     ->creator( 'user A' )
		  ),
	Pangloss::Term->new
	  ->name('term 3')
	  ->date(3)
	  ->concept('concept 3')
	  ->language('et')
	  ->creator('user 1')
	  ->status(
		   Pangloss::Term::Status->new
		     ->rejected
		     ->date( 4 )
		     ->creator( 'user B' )
		  ),
	Pangloss::Term->new
	  ->name('blah (term 4)')
	  ->date(4)
	  ->concept('concept 1')
	  ->language('et')
	  ->creator('user 3'),
	  # default status of pending
       );
}

1;
