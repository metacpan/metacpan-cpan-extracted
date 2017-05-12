package Test;
use Moose;
with 'Mongoose::Document';
with 'MongooseX::JSMethod';

has name     => (is => 'rw', isa => 'Str');
has value    => (is => 'rw', isa => 'Int');
has children => (is => 'rw', isa => 'Mongoose::Join[Test]', default => sub{Mongoose::Join->new(with_class => __PACKAGE__)});
                                                                            
jsmethod(sum => << 'EOJS');                                                 
      var sum = this.value + 0;
      this.children.forEach(function(x){                                    
         sum += x.fetch().sum();
      });
      return sum;
EOJS

42
