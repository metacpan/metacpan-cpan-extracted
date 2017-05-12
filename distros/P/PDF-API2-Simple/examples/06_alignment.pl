 #!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $pdf = PDF::API2::Simple->new( 
				 file => '06_alignment.pdf'
				);

$pdf->add_font('Verdana');
$pdf->add_page();

# left align
{
  my $y = $pdf->height - 50;

  # autoflow off
  $pdf->text( 'Please align me left',
	       x => $pdf->margin_left,
	       y => $y,
	       align => 'left',
	       autoflow => 'off'
	    );

  # autoflow on
  $y -= 50;
  $pdf->text( 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left. '
	      . 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left. '
	      . 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left. '
	      . 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left.',
	       x => $pdf->margin_left,
	       y => $y,
	       align => 'left',
	       autoflow => 'on'
	    );

  $y -= 150;
  $pdf->text( 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left. '
	      . 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left. '
	      . 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left.',
	       x => $pdf->margin_left + 100,
	       y => $y,
	       align => 'left',
	       autoflow => 'on'
	    );

  $y -= 150;
  $pdf->text( 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left. '
	      . 'Please align me left, Please align me left. Please align me left, Please align me left. Please align me left, Please align me left.',
	       x => $pdf->margin_left + 50,
	       y => $y,
	       align => 'left',
	       autoflow => 'on'
	    );
}

$pdf->add_page();

# center align
{
  my $y = $pdf->height - 50;
  my $x = ($pdf->width / 2);

  # autoflow off
  $pdf->text( 'Please align me center',
	       x => $x,
	       y => $y,
	       align => 'center',
	       autoflow => 'off'
	    );

  # autoflow on
  $y -= 50;
  $pdf->text( 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.'
	      . 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.'
	      . 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.'
	      . 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.',
	       x => $x,
	       y => $y,
	       align => 'center',
	       autoflow => 'on'
	    );

  $y -= 150;
  $pdf->text( 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.'
	      . 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.'
	      . 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.',
	       x => $x + 150,
	       y => $y,
	       align => 'center',
	       autoflow => 'on'
	    );

  $y -= 150;
  $pdf->text( 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.'
	      . 'Please align me center, Please align me center. Please align me center, Please align me center. Please align me center, Please align me center.',
	       x => $x - 150,
	       y => $y,
	       align => 'center',
	       autoflow => 'on'
	    );
}

$pdf->add_page();

# right align
{
  my $y = $pdf->height - 50;

  # autoflow off
  $pdf->text( 'Please align me right',
	       x => $pdf->width_right,
	       y => $y,
	       align => 'right',
	       autoflow => 'off'
	    );

  # autoflow on
  $y -= 50;
  $pdf->text( 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.'
	      . 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.'
	      . 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.'
	      . 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.',
	       x => $pdf->width_right,
	       y => $y,
	       align => 'right',
	       autoflow => 'on'
	    );

  $y -= 150;
  $pdf->text( 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.'
	      . 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.'
	      . 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.',
	       x => $pdf->width_right - 150,
	       y => $y,
	       align => 'right',
	       autoflow => 'on'
	    );

  $y -= 150;
  $pdf->text( 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.'
	      . 'Please align me right, Please align me right. Please align me right, Please align me right. Please align me right, Please align me right.',
	       x => $pdf->width_right - 50,
	       y => $y,
	       align => 'right',
	       autoflow => 'on'
	    );
}

$pdf->save();

