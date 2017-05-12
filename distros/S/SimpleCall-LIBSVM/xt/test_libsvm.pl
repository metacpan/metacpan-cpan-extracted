#!/usr/bin/perl
use lib '../lib';
use SimpleCall::LIBSVM;

my $s = SimpleCall::LIBSVM->new();

#train

my %data_opt = (
    type => 'Species', 
    data => [ qw/SepalLength SepalWidth PetalLength PetalWidth/ ], 
);

my $train = 'iris_train.csv';
my $train_opt = '-h 0';

my ($train_data, $train_type) = $s->conv_file_to_libsvm($train, %data_opt);
my $train_model = $s->train_libsvm($train_data, "$train.libsvm.model", train_opt => $train_opt);

# test

my $test = 'iris_test.csv';
my $predict_opt = '';

my ($test_data, $test_type) = $s->conv_file_to_libsvm($test, 
    libsvm_type => $train_type, 
    %data_opt,
);
my $test_out = $s->predict_libsvm($test_data, $train_model, "$test.libsvm.out", predict_opt=>$predict_opt);
my $test_predict_f = $s->conv_libsvm_to_file($test, 
    libsvm_type=> $test_type, 
    libsvm_out => $test_out,
    predict_file => "$test.predict.csv",
);
