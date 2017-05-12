package Storm::Flood::Plan;
{
  $Storm::Flood::Plan::VERSION = '0.240';
}


plan_field FirstName => (
    
);

plan 'TIMs::Model::Employee' => (
    first_name => FirstName,
    last_name => SurName,
    hire_date => 'TIMs::Model::Hire',
    term_date => sub {
        int ( rand time % 2);
        
    }
);


