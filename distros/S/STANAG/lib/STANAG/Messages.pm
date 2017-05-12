
package STANAG::Messages;

use Exporter 'import';
our @EXPORT = qw(%messages);

my @header = qw (  
      IDD:Z10 
      Message_Instance:i 
      Message_Type:I 
      Message_Length:I 
      Stream_ID:i 
      Packet_Sequence:i );
my @footer = qw ( Checksum:I );

our %messages = (
    CUCS_Authorisation_Request => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d 
      Vehicle_ID:i 
      CUCS_ID:i 
      VSM_ID:i 
      Data_Link_ID:i 
      Vehicle_Type:S 
      Vehicle_Subtype:S 
      RequestedHandover_LOI:C 
      Controlled_Station:I 
      Controlled_Station_Mode:C
      Wait_for_Vehicle_Data_Link_Transition_Coordination_Message:C),
    @footer]),
    Vehicle_ID => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d 
      Vehicle_ID:i 
      CUCS_ID:i 
      VSM_ID:i 
      Vehicle_ID_Update:i 
      Vehicle_Type:S  
      Vehicle_Subtype:S 
      Owning_Country_Code:C 
      Tail_Number:Z16 
      Mission_ID:Z20 
      ATC_Call_Sign:Z32),
    @footer]),
    VSM_Authorization_Response => new Parse::Binary::FixedFormat([
    @header, qw (   
      Time_Stamp:d 
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Data_Link_ID:i
      LOI_Authorized:C
      LOI_Granted:C
      Controlled_Station:I
      Controlled_Station_Mode:C
      Vehicle_Type:S
      Vehicle_Subtype:S
      ), @footer]),
    Vehicle_Configuration_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Initial_Propulsion_Energy:f
      ), @footer]),
    Loiter_Configuration => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Loiter_type:C
      Loiter_Radius:f
      Loiter_Length:f
      Loiter_Bearing:f
      Loiter_Direction:C
      Loiter_altitude:f
      Altitude_Type:C
      Loiter_Speed:f
      Speed_Type:C
      ), @footer]),
    Vehicle_Operating_Mode_Report => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Select_Flight_Path_Control_Mode:C
      ), @footer]),
    Vehicle_Steering_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Altitude_Command_Type:C
      Commanded_Altitude:f
      Commanded_Vertical_Speed:f
      Heading_Command_Type:C
      Commanded_Heading:f
      Commanded_Course:f
      Commanded_Turn_Rate:f
      Commanded_Roll_Rate:f
      Commanded_Roll:f
      Commanded_Speed:f
      Speed_Type:C
      Commanded_Waypoint_Number:S
      Altimeter_Setting:f
      Altitude_Type:C
      Loiter_Position_Latitude:d
      Loiter_Position_Longitude:d
      ), @footer]),
    Air_Vehicle_Lights => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Set_Lights:S
      ), @footer]),
    Engine_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Engine_Number:i
      Engine_Command:C
      ), @footer]),
    Flight_Termination_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Commanded_Flight_Termination_State:C
      Flight_Termination_Mode:C
      ), @footer]),
    Relative_Route_Absolute_Reference => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Latitude_Yaxis_zero:d
      Longitude_Xaxis_zero:d
      Altitude_Type:C
      Altitude:f
      Orientation:f
      Route_ID:Z20
      ), @footer]),
    Mode_Preference_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Altitude_Mode:C
      Speed_Mode:C
      CourseHeading_Mode:C
      ), @footer]),
    Vehicle_Configuration => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Configuration_ID:I
      Propulsion_Fuel_Capacity:f
      Propulsion_Battery_Capacity:f
      Maximum_Indicated_Airspeed:f
      Optimum_Cruise_Indicated_Airspeed:f
      Optimum_Endurance_Indicated_Airspeed:f
      Maximum_Load_Factor:f
      Gross_Weight:f
      X_CG:f
      Number_of_Engines:C
      ), @footer]),
    Inertial_States => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Latitude:d
      Longitude:d
      Altitude:f
      Altitude_Type:C
      U_Speed:f
      V_Speed:f
      W_Speed:f
      U_Accel:f
      V_Accel:f
      W_Accel:f
      Phi:f
      Theta:f
      Psi:f
      Phi_dot:f
      Theta_dot:f
      Psi_dot:f
      Magnetic_Variation:f
      ), @footer]),
    Air_and_Ground_Relative_States => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Angle_of_Attack:f
      Angle_of_Sideslip:f
      True_Airspeed:f
      Indicated_Airspeed:f
      Outside_Air_Temp:f
      U_Wind:f
      V_Wind:f
      Altimeter_Setting:f
      Barometric_Altitude:f
      Barometric_Altitude_Rate:f
      Pressure_Altitude:f
      AGL_Altitude:f
      WGS84_Altitude:f
      U_Ground:f
      V_Ground:f
      ), @footer]),
    BodyRelative_Sensed_States => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      X_Body_Accel:f
      Y_Body_Accel:f
      Z_Body_Accel:f
      Roll_Rate:f
      Pitch_Rate:f
      Yaw_Rate:f
      ), @footer]),
    Vehicle_Operating_States => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Commanded_Altitude:f
      Altitude_Type:C
      Commanded_Heading:f
      Commanded_Course:f
      Commanded_Turn_Rate:f
      Commanded_Roll_Rate:f
      Commanded_Speed:f
      Speed_Type:C
      Power_Level:s
      Flap_Deployment_Angle:c
      Speed_Brake_Deployment_Angle:c
      Landing_Gear_State:C
      Current_Propulsion_Energy_Level:f
      Current_Propulsion_Energy_Usage_Rate:f
      Commanded_Roll:f
      Altitude_Command_Type:C
      Heading_Command_Type:C
      ), @footer]),
    Engine_Operating_States => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Engine_Number:i
      Engine_Status:C
      Reported_Engine_Command:C
      Engine_Power_Setting:f
      Engine_Speed:f
      Engine_Speed_Status:C
      Output_Power_Shaft_Torque_Status:C
      Engine_Body_Temperature_Status:C
      Exhaust_Gas_Temperature_Status:C
      Coolant_Temperature_Status:C
      Lubricant_Pressure_Status:C
      Lubricant_Temperature_Status:C
      Fire_Detection_Sensor_Status:C
      ), @footer]),
    Vehicle_Operating_Mode_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Select_Flight_Path_Control_Mode:C
      ), @footer]),
    Vehicle_Lights_State => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Navigation_Lights_State:S
      ), @footer]),
    Flight_Termination_Mode_Report => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Reported_Flight_Termination_State:C
      Reported_Flight_Termination_Mode:C
      ), @footer]),
    Mode_Preference_Report => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Altitude_Mode_State:C
      Speed_Mode_State:C
      CourseHeading_Mode_State:C
      ), @footer]),
    From_To_Next_Waypoint_States => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Altitude_Type:C
      Speed_Type:C
      From_Waypoint_Latitude:d
      From_Waypoint_Longitude:d
      From_Waypoint_Altitude:f
      From_Waypoint_Time:d
      From_Waypoint_Number:S
      To_Waypoint_Latitude:d
      To_Waypoint_Longitude:d
      To_Waypoint_Altitude:f
      To_Waypoint_Speed:f
      To_Waypoint_Time:d
      To_Waypoint_Number:S
      Next_Waypoint_Latitude:d
      Next_Waypoint_Longitude:d
      Next_Waypoint_Altitude:f
      Next_Waypoint_Airspeed:f
      Next_Waypoint_Time:d
      Next_Waypoint_Number:S
      ), @footer]),
    Payload_Steering_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Set_Centreline_Azimuth_Angle:f
      Set_Centreline_Elevation_Angle:f
      Set_Zoom:C
      Set_Horizontal_Field_Of_View:f
      Set_Vertical_Field_Of_View:f
      Horizontal_Slew_Rate:f
      Vertical_Slew_Rate:f
      Latitude:d
      Longitude:d
      Altitude:f
      Altitude_Type:C
      Set_Focus:C
      Focus_Type:C
      ), @footer]),
    EOIRLaser_Payload_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Addressed_Sensor:C
      System_Operating_Mode:C
      Set_EO_Sensor_Mode:C
      Set_IR_Polarity:C
      Image_Output:C
      Set_EOIR_Pointing_Mode:C
      Fire_Laser_PointerRangefinder:C
      Select_Laser_Rangefinder:C
      Set_Laser_Designator_Code:S
      Initiate_Laser_Designator:C
      Preplan_Mode:C
      ), @footer]),
    SAR_Payload_Commands => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Set_Radar_State:C
      Set_MTI_Radar_Mode:C
      Set_SAR_Modes:Z6
      Set_Radar_Resolution:s
      ), @footer]),
    Stores_Management_System_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Power_Command:C
      Active_Weapon_Mode_Command:C
      Active_Target_Acquisition_Mode_Select:C
      Active_Attack_Mode:C
      RackRail_Ejector_Enable_Hung_ordnance:C
      Safety_Enable_Discrete_Command:C
      Set_Target_Latitude:d
      Set_Target_Longitude:d
      Set_Target_Altitude:f
      Target_Altitude_Type:C
      Set_Target_Inertial_Speed_Vx:f
      Set_Target_Inertial_Speed_Vy:f
      Set_Target_Inertial_Speed_Vz:f
      ), @footer]),
    Communications_Relay_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Set_Relay_State:C
      ), @footer]),
    Payload_Data_Recorder_Control_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Recording_Device_Number:C
      Set_Recording_Index_Type:C
      Set_Recording_Mode:C
      Set_Recording_Rate:f
      Initial_Recording_Index:i
      Set_Replay_Mode:C
      Replay_Clock_Rate:f
      Seek_Replay_Index:i
      ), @footer]),
    Payload_Bay_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Payload_Bay_Doors:C
      ), @footer]),
    Terrain_Data_Update => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Latitude_of_terrain_data_point:d
      Longitude_of_terrain_data_point:d
      Elevation_of_terrain_data_point:f
      ), @footer]),
    Payload_Configuration => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Payload_Stations_Available:I
      Station_Number:I
      Payload_Type:S
      Station_Door:C
      Number_of_Payload_Recording_Devices:C
      ), @footer]),
    EOIR_Configuration_State => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Station_Number:I
      EOIR_Type:Z14
      EOIR_Type_Revision_Level:C
      EO_Vertical_Image_Dimension:s
      EO_Horizontal_Image_Dimension:s
      IR_Vertical_Image_Dimension:s
      IR_Horizontal_Image_Dimension:s
      Field_of_Regard_Elevation_Min:f
      Field_of_Regard_Elevation_Max:f
      Field_of_Regard_Azimuth_Min:f
      Field_of_Regard_Azimuth_Max:f
      ), @footer]),
    Stores_Management_System_Status => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Active_Weapon_Type:C
      Active_Weapon_Sensors:C
      Active_Weapon_Number_per_Station:C
      Active_Target_Acquisition_Mode:C
      Active_Attack_Mode:C
      Weapon_Initialising:C
      Weapon_Release_Clearance:C
      Clearance_Validity:C
      Weapon_Power_State:C
      Weapon_Status:C
      RackRailEjector_Unlock:C
      Safety_Enable_Discrete_State:C
      Launch_Acceptable_Region_LAR_Status:C
      Safe_Separation_Status_Weapon:C
      Number_of_Stores_Available:C
      ), @footer]),
    Communications_Relay_Status => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Report_Relay_State:C
      ), @footer]),
    Payload_Data_Recorder_Status => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Recording_Device_Number:C
      Active_Index_Type:C
      Recording_Status:C
      Record_Rate:f
      Current_Recording_Index:i
      Record_Index_Time_Stamp:d
      Replay_Status:C
      Replay_Rate:f
      Current_Replay_Index:i
      Health_Status_Code:s
      ), @footer]),
    Payload_Bay_Status => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Station_Number:I
      Payload_Bay_Door_Status:C
      ), @footer]),
    Data_Link_Control_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Data_Link_ID:i
      Addressed_Terminal:C
      Set_Data_Link_State:C
      Set_Antenna_Mode:C
      Communication_Security_Mode:C
      Link_Channel_Priority:C
      ), @footer]),
    Pedistal_Control_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Data_Link_ID:i
      Addressed_Pedestal:C
      Set_Pedestal_Mode:C
      Set_Antenna_Azimuth:f
      Set_Antenna_Elevation:f
      Set_Azimuth_Offset:f
      Set_Elevation_Offset:f
      Set_Azimuth_Slew_Rate:f
      Set_Elevation_Slew_Rate:f
      ), @footer]),
    Data_Link_Assignment_Request => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Data_Link_ID:i
      Control_Assignment_Request:C
      Vehicle_Type:S
      Vehicle_Subtype:S
      ), @footer]),
    Data_Link_Configuration => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Data_Link_ID:i
      Data_Link_Control_Availability:C
      Terminal_Type:C
      Data_Link_Type:C
      Data_Link_Name:Z20
      Antenna_Type:C
      Vehicle_Type:S
      Vehicle_Subtype:S
      ), @footer]),
    Data_Link_Status_Report => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Data_Link_ID:i
      Addressed_Terminal:C
      Data_Link_State:C
      Antenna_State:C
      Reported_Channel:S
      Reported_Primary_Hop_Pattern:C
      Reported_Forward_Link_FL_Carrier_Frequency:f
      Reported_Return_Link_RL_Carrier_Frequency:f
      Downlink_Status:s
      Communication_Security_State:C
      Link_Channel_Priority_State:C
      ), @footer]),
    Data_Link_Control_Command_Status => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Data_Link_ID:i
      Addressed_Terminal:C
      Reported_Demanded_Data_Link_State:C
      Reported_Demanded_Antenna_Mode:C
      Reported_Demanded_Communication_Security_Mode:C
      ), @footer]),
    Mission_Upload_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Mission_ID:Z20
      Mission_Plan_Mode:C
      Waypoint_Number:S
      ), @footer]),
    AV_Loiter_Waypoint => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Waypoint_Number:S
      Waypoint_Loiter_Time:S
      Waypoint_Loiter_Type:C
      Loiter_Radius:f
      Loiter_Length:f
      Loiter_Bearing:d
      Loiter_Direction:C
      ), @footer]),
    Payload_Action_Waypoint => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Waypoint_Number:S
      Station_Number:I
      Set_Sensor_1_Mode:C
      Set_Sensor_2_Mode:C
      Sensor_Output:C
      Set_Sensor_Pointing_Mode:C
      Starepoint_Latitude:d
      Starepoint_Longitude:d
      Starepoint_Altitude:f
      Starepoint_Altitude_Type:C
      Payload_Az_wrt_AV:f
      Payload_El_wrt_AV:f
      Payload_Sensor_Rotation_Angle:f
      ), @footer]),
    Airframe_Action_Waypoint => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Waypoint_Number:S
      Function:C
      Enumerated_State:C
      ), @footer]),
    Vehicle_Specific_Waypoint => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Waypoint_Number:S
      Tag_Type:C
      TagData:Z20
      ), @footer]),
    Mission_UploadDownload_Status => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Status:C
      Percent_Complete:C
      ), @footer]),
    Subsystem_Status_Request => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Subsystem_ID:I
      ), @footer]),
    Subsystem_Status_Detail_Request => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Subsystem_State_Report_Reference:i
      ), @footer]),
    Subsystem_Status_Alert_Message => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Priority:C
      Subsystem_State_Report_Reference:i
      Subsystem_ID:C
      Type:C
      Warning_ID:i
      Text:Z80
      Persistence:Signed1
      ), @footer]),
    Subsystem_Status_Report => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      Subsystem_ID:C
      Subsystem_State:C
      Subsystem_State_Report_Reference:i
      ), @footer]),
    Field_Configuration_Request => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Data_Link_ID:i
      Request_Type:C
      Requested_Message:I
      Requested_Field:C
      Station_Number:I
      Sensor_Select:C
      ), @footer]),
    Display_Unit_Request => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Distance:C
      Altitude:C
      Speed:C
      Position_Latitude:C
      Temperature:C
      MassWeight:C
      Angles:C
      Pressure_Barometric:C
      Fuel_Quantity:C
      ), @footer]),
    Configuration_Complete => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Data_Link_ID:i
      Station_Number:I
      Vehicle_Type:S
      Vehicle_Subtype:S
      ), @footer]),
    Field_Configuration_Integer_Response => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_ID:i
      Data_Link_ID:i
      Station_Number:I
      Requested_Message:I
      Requested_Field:C
      Field_Supported:C
      Max_Value:i
      Min_Value:i
      Max_Display_Value:i
      Min_Display_Value:i
      Minimum_Display_Resolution:i
      High_Caution_Limit:i
      High_Warning_Limit:i
      Low_Caution_Limit:i
      Low_Warning_Limit:i
      Help_Text:Z80
      Subsystem_ID:C
      ), @footer]),
    Field_Configuration_Command => new Parse::Binary::FixedFormat([
    @header, qw (
      Time_Stamp:d
      Vehicle_ID:i
      CUCS_ID:i
      VSM_Home_Web_Page_URL:Z249
      FTP_URL:Z249
      ), @footer]) 
);
