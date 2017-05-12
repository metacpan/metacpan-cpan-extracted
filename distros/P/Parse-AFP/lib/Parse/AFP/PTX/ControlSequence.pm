# $URL: //local/member/autrijus/Parse-AFP/lib/Parse/AFP/PTX/ControlSequence.pm $ $Author: autrijus $
# $Rev: 1130 $ $Date: 2004-02-17T15:40:29.640821Z $

package Parse::AFP::PTX::ControlSequence;
use base 'Parse::AFP::Base';

use constant FORMAT => (
    Length	=> 'C',
    ControlCode	=> 'H2',
    Data	=> 'a*',
);
use constant DISPATCH_FIELD => 'ControlCode';
use constant DISPATCH_TABLE => (
    74	=> 'PTX::STC',	    75	=> 'PTX::STC',	    # Set Text Color
    c0	=> 'PTX::SIM',	    c1	=> 'PTX::SIM',	    # Set Inline Margin
    c2	=> 'PTX::SIA',	    c3	=> 'PTX::SIA',	    # Set Intercharacter Adjustment
    c4	=> 'PTX::SVI',	    c5	=> 'PTX::SVI',	    # Set Variable-Space Character Increment
    c6	=> 'PTX::AMI',	    c7	=> 'PTX::AMI',	    # Absolute Move Inline
    c8	=> 'PTX::RMI',	    c9	=> 'PTX::RMI',	    # Relative Move Inline
    d0	=> 'PTX::SBI',	    d1	=> 'PTX::SBI',	    # Set Baseline Increment
    d2	=> 'PTX::AMB',	    d3	=> 'PTX::AMB',	    # Absolute Move Baseline
    d4	=> 'PTX::RMB',	    d5	=> 'PTX::RMB',	    # Relative Move Baseline
    d8	=> 'PTX::BLN',	    d9	=> 'PTX::BLN',	    # Begin Line Next
    e4	=> 'PTX::DIR',	    e5  => 'PTX::DIR',	    # Draw I-Axis Rule
    e6	=> 'PTX::DBR',	    e7  => 'PTX::DBR',	    # Draw B-Axis Rule
    ee	=> 'PTX::RPS',	    ef  => 'PTX::RPS',	    # Repeat String
    f0	=> 'PTX::SCFL',	    f1	=> 'PTX::SCFL',	    # Set Coded Font Local
    f2	=> 'PTX::BSU',	    f3	=> 'PTX::BSU',	    # Begin Suppression
    f4	=> 'PTX::ESU',	    f5	=> 'PTX::ESU',	    # Begin Suppression
    f6	=> 'PTX::STO',	    f7	=> 'PTX::STO',	    # Set Text Orientation
    f8	=> 'PTX::NOP',	    f9	=> 'PTX::NOP',	    # No Operation
    da	=> 'PTX::TRN',	    db	=> 'PTX::TRN',	    # Transparent Data
);

1;
