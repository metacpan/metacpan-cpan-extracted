package Req1; {
   use Object::InsideOut;

   my @field :Field
             :Arg('Name' => 'field', Mand => 1)
             :Standard('field');
}

package Req4; {
   use Object::InsideOut;

   my @field :Field
             :Arg('Name' => 'fld', Mand => 1)
             :Standard('fld');
}
1;
