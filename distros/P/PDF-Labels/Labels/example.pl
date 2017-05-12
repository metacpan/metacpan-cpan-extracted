#!/bin/perl

use PDF::Create;
use PDF::Labels;

$pdf = new PDF::Labels(
		$PDF::Labels::PageFormats[2],
			filename=>'labels.pdf',
			Author=>'PDF Labelmaker',
			Title=>'My Labels'
		);

$pdf->setlabel(35);      # Start with label 5 on first page

$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');
$pdf->label('John Doe', '1234 Some Street', 'Anytown, ID', '12345');
$pdf->label('Jane Doe', '5493 Other Drive', 'Nowhere, CA', '92213');
$pdf->label('Bob Smith', '392 Cedar Lane', 'Deep Shit, AR', '72134');

$pdf->close();
