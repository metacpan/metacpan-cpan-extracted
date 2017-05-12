use strict;
use Rinchi::CIGIPP;
use Rinchi::CIGIPP::DefaultHandler;

my @packets;

my $ig_ctl = Rinchi::CIGIPP::IGControl->new();
push @packets,$ig_ctl;

my $packet_type = $ig_ctl->packet_type();
my $packet_size = $ig_ctl->packet_size();
my $major_version = $ig_ctl->major_version();
my $database_number = $ig_ctl->database_number(65);
my $minor_version = $ig_ctl->minor_version();
my $extrapolation_enable = $ig_ctl->extrapolation_enable(Rinchi::CIGIPP->Disable);
my $timestamp_valid = $ig_ctl->timestamp_valid(Rinchi::CIGIPP->Invalid);
my $ig_mode = $ig_ctl->ig_mode(Rinchi::CIGIPP->Standby);
my $magic_number = $ig_ctl->magic_number();
my $host_frame_number = $ig_ctl->host_frame_number(38591);
my $timestamp = $ig_ctl->timestamp(52141);
my $last_igframe_number = $ig_ctl->last_igframe_number(47470);

my $buffer = $ig_ctl->pack();
#print "IGControl buffer length: ",length($buffer),"\n";

my $ent_ctl = Rinchi::CIGIPP::EntityControl->new();
push @packets,$ent_ctl;

my $packet_type = $ent_ctl->packet_type();
my $packet_size = $ent_ctl->packet_size();
my $entity_ident = $ent_ctl->entity_ident(18430);
my $ground_clamp = $ent_ctl->ground_clamp(0);
my $inherit_alpha = $ent_ctl->inherit_alpha(1);
my $collision_detection_enable = $ent_ctl->collision_detection_enable(1);
my $attach_state = $ent_ctl->attach_state(Rinchi::CIGIPP->Attach);
my $entity_state = $ent_ctl->entity_state(Rinchi::CIGIPP->EntityInactive);
my $extrapolation_enable = $ent_ctl->extrapolation_enable(Rinchi::CIGIPP->Disable);
my $animation_state = $ent_ctl->animation_state(Rinchi::CIGIPP->Stop);
my $animation_loop = $ent_ctl->animation_loop(Rinchi::CIGIPP->Continuous);
my $animation_direction = $ent_ctl->animation_direction(Rinchi::CIGIPP->Backward);
my $alpha = $ent_ctl->alpha(249);
my $entity_type = $ent_ctl->entity_type(54457);
my $parent_ident = $ent_ctl->parent_ident(38194);
my $roll = $ent_ctl->roll(36.539);
my $pitch = $ent_ctl->pitch(15.394);
my $yaw = $ent_ctl->yaw(53.214);
my $latitude = $ent_ctl->latitude(4.828);
#my $x_offset = $ent_ctl->x_offset(22.092);
my $longitude = $ent_ctl->longitude(33.727);
#my $y_offset = $ent_ctl->y_offset(71.648);
my $altitude = $ent_ctl->altitude(20.674);
#my $z_offset = $ent_ctl->z_offset(81.962);

my $buffer = $ent_ctl->pack();
#print "EntityControl buffer length: ",length($buffer),"\n";

my $ccent_ctl = Rinchi::CIGIPP::ConformalClampedEntityControl->new();
push @packets,$ccent_ctl;

my $packet_type = $ccent_ctl->packet_type();
my $packet_size = $ccent_ctl->packet_size();
my $entity_ident = $ccent_ctl->entity_ident(57935);
my $yaw = $ccent_ctl->yaw(39.75);
my $latitude = $ccent_ctl->latitude(57.645);
my $longitude = $ccent_ctl->longitude(70.599);

my $buffer = $ccent_ctl->pack();
#print "ConformalClampedEntityControl buffer length: ",length($buffer),"\n";

my $cmp_ctl = Rinchi::CIGIPP::ComponentControl->new();
push @packets,$cmp_ctl;

my $packet_type = $cmp_ctl->packet_type();
my $packet_size = $cmp_ctl->packet_size();
my $component_ident = $cmp_ctl->component_ident(37562);
my $instance_ident = $cmp_ctl->instance_ident(26282);
my $component_class = $cmp_ctl->component_class(Rinchi::CIGIPP->EntityCC);
my $component_state = $cmp_ctl->component_state(245);
my $data1 = $cmp_ctl->data1(1104543744);
#my $data1 = $cmp_ctl->data1_float(26.75);
#my $data2 = $cmp_ctl->data2(383);
my $data2_s1 = $cmp_ctl->data2_short1(0x5A5A);
my $data2_s2 = $cmp_ctl->data2_short2(0xA5A5);
my $data3 = $cmp_ctl->data3(25589);
my $data4 = $cmp_ctl->data4(28613);
my $data5 = $cmp_ctl->data5(23541);
my $data6 = $cmp_ctl->data6(43464);

my $buffer = $cmp_ctl->pack();
#print "ComponentControl buffer length: ",length($buffer),"\n";
#print "Little Endian: $cmp_ctl->{'_LittleEndian'}\n";
#print "Data 1: ",$cmp_ctl->data1(),",",$cmp_ctl->data1_float(),"\n";
#print sprintf("Data 2: 0x%08X\n",$cmp_ctl->data2());

my $scmp_ctl = Rinchi::CIGIPP::ShortComponentControl->new();
push @packets,$scmp_ctl;

my $packet_type = $scmp_ctl->packet_type();
my $packet_size = $scmp_ctl->packet_size();
my $component_ident = $scmp_ctl->component_ident(8600);
my $instance_ident = $scmp_ctl->instance_ident(3133);
my $component_class = $scmp_ctl->component_class(Rinchi::CIGIPP->ViewCC);
my $component_state = $scmp_ctl->component_state(67);
my $data1 = $scmp_ctl->data1(1078530000);
#my $data1 = $scmp_ctl->data1_float(3.14159);
my $data2 = $scmp_ctl->data2(31535);
my $buffer = $scmp_ctl->pack();
#print "ShortComponentControl buffer length: ",length($buffer),"\n";
#print "Little Endian: $scmp_ctl->{'_LittleEndian'}\n";
#print "Data 1: ",$scmp_ctl->data1(),",",$scmp_ctl->data1_float(),"\n";
my $data1and2 = $scmp_ctl->data1_and_2_double(2.71828182845904523536028747135266249775724709369996);
#print "Data 1 and 2: ",$scmp_ctl->data1_and_2_double(),",",$scmp_ctl->data1(),",",$scmp_ctl->data2(),"\n";

my $data1 = $scmp_ctl->data1(1074118410);
my $data2 = $scmp_ctl->data2(2333366121);
#my $data2 = $scmp_ctl->data2(0);
#print "Data 1 and 2: ",$scmp_ctl->data1_and_2_double(),",",$scmp_ctl->data1(),",",$scmp_ctl->data2(),"\n";

my $ap_ctl = Rinchi::CIGIPP::ArticulatedPartControl->new();
push @packets,$ap_ctl;

my $packet_type = $ap_ctl->packet_type();
my $packet_size = $ap_ctl->packet_size();
my $entity_ident = $ap_ctl->entity_ident(63243);
my $articulated_part_ident = $ap_ctl->articulated_part_ident(6);
my $yaw_enable = $ap_ctl->yaw_enable(Rinchi::CIGIPP->Disable);
my $pitch_enable = $ap_ctl->pitch_enable(Rinchi::CIGIPP->Enable);
my $roll_enable = $ap_ctl->roll_enable(Rinchi::CIGIPP->Enable);
my $z_offset_enable = $ap_ctl->z_offset_enable(Rinchi::CIGIPP->Disable);
my $y_offset_enable = $ap_ctl->y_offset_enable(Rinchi::CIGIPP->Enable);
my $x_offset_enable = $ap_ctl->x_offset_enable(Rinchi::CIGIPP->Disable);
my $articulated_part_enable = $ap_ctl->articulated_part_enable(Rinchi::CIGIPP->Enable);
my $x_offset = $ap_ctl->x_offset(3.419);
my $y_offset = $ap_ctl->y_offset(55.33);
my $z_offset = $ap_ctl->z_offset(80.089);
my $roll = $ap_ctl->roll(2.203);
my $pitch = $ap_ctl->pitch(81.151);
my $yaw = $ap_ctl->yaw(61.683);

my $buffer = $ap_ctl->pack();
#print "ArticulatedPartControl buffer length: ",length($buffer),"\n";

my $sap_ctl = Rinchi::CIGIPP::ShortArticulatedPartControl->new();
push @packets,$sap_ctl;

my $packet_type = $sap_ctl->packet_type();
my $packet_size = $sap_ctl->packet_size();
my $entity_ident = $sap_ctl->entity_ident(15419);
my $articulated_part_ident1 = $sap_ctl->articulated_part_ident1(124);
my $articulated_part_ident2 = $sap_ctl->articulated_part_ident2(21);
my $articulated_part_enable2 = $sap_ctl->articulated_part_enable2(Rinchi::CIGIPP->Enable);
my $articulated_part_enable1 = $sap_ctl->articulated_part_enable1(Rinchi::CIGIPP->Disable);
my $dof_select2 = $sap_ctl->dof_select2(Rinchi::CIGIPP->NotUsed);
my $dof_select1 = $sap_ctl->dof_select1(Rinchi::CIGIPP->XOffset);
my $degree_of_freedom1 = $sap_ctl->degree_of_freedom1(2.007);
my $degree_of_freedom2 = $sap_ctl->degree_of_freedom2(49.352);

my $buffer = $sap_ctl->pack();
#print "ShortArticulatedPartControl buffer length: ",length($buffer),"\n";

my $rate_ctl = Rinchi::CIGIPP::RateControl->new();
push @packets,$rate_ctl;

my $packet_type = $rate_ctl->packet_type();
my $packet_size = $rate_ctl->packet_size();
my $entity_ident = $rate_ctl->entity_ident(5635);
my $articulated_part_ident = $rate_ctl->articulated_part_ident(210);
my $coordinate_system = $rate_ctl->coordinate_system(Rinchi::CIGIPP->World_Parent);
my $apply_to_articulated_part = $rate_ctl->apply_to_articulated_part(Rinchi::CIGIPP->True);
my $x_linear_rate = $rate_ctl->x_linear_rate(6.206);
my $y_linear_rate = $rate_ctl->y_linear_rate(32.738);
my $z_linear_rate = $rate_ctl->z_linear_rate(84.401);
my $roll_angular_rate = $rate_ctl->roll_angular_rate(47.174);
my $pitch_angular_rate = $rate_ctl->pitch_angular_rate(25.245);
my $yaw_angular_rate = $rate_ctl->yaw_angular_rate(36.996);

my $buffer = $rate_ctl->pack();
#print "RateControl buffer length: ",length($buffer),"\n";

my $sky_ctl = Rinchi::CIGIPP::CelestialSphereControl->new();
push @packets,$sky_ctl;

my $packet_type = $sky_ctl->packet_type();
my $packet_size = $sky_ctl->packet_size();
my $hour = $sky_ctl->hour(123);
my $minute = $sky_ctl->minute(7);
my $date_time_valid = $sky_ctl->date_time_valid(Rinchi::CIGIPP->Invalid);
my $star_field_enable = $sky_ctl->star_field_enable(Rinchi::CIGIPP->Disable);
my $moon_enable = $sky_ctl->moon_enable(Rinchi::CIGIPP->Disable);
my $sun_enable = $sky_ctl->sun_enable(Rinchi::CIGIPP->Disable);
my $ephemeris_model_enable = $sky_ctl->ephemeris_model_enable(Rinchi::CIGIPP->Enable);
my $date = $sky_ctl->date(5486);
my $star_field_intensity = $sky_ctl->star_field_intensity(29.575);

my $buffer = $sky_ctl->pack();
#print "CelestialSphereControl buffer length: ",length($buffer),"\n";

my $atmos_ctl = Rinchi::CIGIPP::AtmosphereControl->new();
push @packets,$atmos_ctl;

my $packet_type = $atmos_ctl->packet_type();
my $packet_size = $atmos_ctl->packet_size();
my $atmospheric_model_enable = $atmos_ctl->atmospheric_model_enable(Rinchi::CIGIPP->Enable);
my $humidity = $atmos_ctl->humidity(35);
my $air_temperature = $atmos_ctl->air_temperature(23.357);
my $visibility_range = $atmos_ctl->visibility_range(47.803);
my $horizontal_wind_speed = $atmos_ctl->horizontal_wind_speed(55.727);
my $vertical_wind_speed = $atmos_ctl->vertical_wind_speed(40.386);
my $wind_direction = $atmos_ctl->wind_direction(47.212);
my $barometric_pressure = $atmos_ctl->barometric_pressure(17.871);

my $buffer = $atmos_ctl->pack();
#print "AtmosphereControl buffer length: ",length($buffer),"\n";

my $env_ctl = Rinchi::CIGIPP::EnvironmentalRegionControl->new();
push @packets,$env_ctl;

my $packet_type = $env_ctl->packet_type();
my $packet_size = $env_ctl->packet_size();
my $region_ident = $env_ctl->region_ident(20814);
my $merge_terrestrial_surface_conditions = $env_ctl->merge_terrestrial_surface_conditions(Rinchi::CIGIPP->Merge);
my $merge_maritime_surface_conditions = $env_ctl->merge_maritime_surface_conditions(Rinchi::CIGIPP->UseLast);
my $merge_aerosol_concentrations = $env_ctl->merge_aerosol_concentrations(Rinchi::CIGIPP->Merge);
my $merge_weather_properties = $env_ctl->merge_weather_properties(Rinchi::CIGIPP->UseLast);
my $region_state = $env_ctl->region_state(Rinchi::CIGIPP->Active);
my $latitude = $env_ctl->latitude(59.996);
my $longitude = $env_ctl->longitude(81.934);
my $size_x = $env_ctl->size_x(35.271);
my $size_y = $env_ctl->size_y(24.1);
my $corner_radius = $env_ctl->corner_radius(47.747);
my $rotation = $env_ctl->rotation(71.893);
my $transition_perimeter = $env_ctl->transition_perimeter(3.385);

my $buffer = $env_ctl->pack();
#print "EnvironmentalRegionControl buffer length: ",length($buffer),"\n";

my $wthr_ctl = Rinchi::CIGIPP::WeatherControl->new();
push @packets,$wthr_ctl;

my $packet_type = $wthr_ctl->packet_type();
my $packet_size = $wthr_ctl->packet_size();
my $entity_ident = $wthr_ctl->entity_ident(22740);
my $region_ident = $wthr_ctl->region_ident(59769);
my $layer_ident = $wthr_ctl->layer_ident(131);
my $humidity = $wthr_ctl->humidity(89);
my $cloud_type = $wthr_ctl->cloud_type(Rinchi::CIGIPP->None);
my $random_lightning_enable = $wthr_ctl->random_lightning_enable(Rinchi::CIGIPP->Disable);
my $random_winds_enable = $wthr_ctl->random_winds_enable(Rinchi::CIGIPP->Disable);
my $scud_enable = $wthr_ctl->scud_enable(Rinchi::CIGIPP->Enable);
my $weather_enable = $wthr_ctl->weather_enable(Rinchi::CIGIPP->Enable);
my $severity = $wthr_ctl->severity(2);
my $weather_scope = $wthr_ctl->weather_scope(Rinchi::CIGIPP->RegionalScope);
my $air_temperature = $wthr_ctl->air_temperature(15.426);
my $visibility_range = $wthr_ctl->visibility_range(89.817);
my $scud_frequency = $wthr_ctl->scud_frequency(2.31);
my $coverage = $wthr_ctl->coverage(84.412);
my $base_elevation = $wthr_ctl->base_elevation(47.967);
my $thickness = $wthr_ctl->thickness(38.301);
my $transition_band = $wthr_ctl->transition_band(70.407);
my $horizontal_wind_speed = $wthr_ctl->horizontal_wind_speed(45.598);
my $vertical_wind_speed = $wthr_ctl->vertical_wind_speed(85.529);
my $wind_direction = $wthr_ctl->wind_direction(62.819);
my $barometric_pressure = $wthr_ctl->barometric_pressure(82.459);
my $aerosol_concentration = $wthr_ctl->aerosol_concentration(3.569);

my $buffer = $wthr_ctl->pack();
#print "WeatherControl buffer length: ",length($buffer),"\n";

my $msc_ctl = Rinchi::CIGIPP::MaritimeSurfaceConditionsControl->new();
push @packets,$msc_ctl;

my $packet_type = $msc_ctl->packet_type();
my $packet_size = $msc_ctl->packet_size();
my $entity_ident = $msc_ctl->entity_ident(51957);
my $region_ident = $msc_ctl->region_ident(64233);
my $scope = $msc_ctl->scope(Rinchi::CIGIPP->GlobalScope);
my $whitecap_enable = $msc_ctl->whitecap_enable(Rinchi::CIGIPP->Disable);
my $surface_conditions_enable = $msc_ctl->surface_conditions_enable(Rinchi::CIGIPP->Disable);
my $sea_surface_height = $msc_ctl->sea_surface_height(32.113);
my $surface_water_temperature = $msc_ctl->surface_water_temperature(0.898);
my $surface_clarity = $msc_ctl->surface_clarity(56.091);

my $buffer = $msc_ctl->pack();
#print "MaritimeSurfaceConditionsControl buffer length: ",length($buffer),"\n";

my $wave_ctl = Rinchi::CIGIPP::WaveControl->new();
push @packets,$wave_ctl;

my $packet_type = $wave_ctl->packet_type();
my $packet_size = $wave_ctl->packet_size();
my $region_ident = $wave_ctl->region_ident(57556);
my $entity_ident = $wave_ctl->entity_ident(19952);
my $wave_ident = $wave_ctl->wave_ident(240);
my $breaker_type = $wave_ctl->breaker_type(Rinchi::CIGIPP->Plunging);
my $scope = $wave_ctl->scope(Rinchi::CIGIPP->GlobalScope);
my $wave_enable = $wave_ctl->wave_enable(Rinchi::CIGIPP->Enable);
my $wave_height = $wave_ctl->wave_height(83.07);
my $wave_length = $wave_ctl->wave_length(12.084);
my $period = $wave_ctl->period(54.785);
my $direction = $wave_ctl->direction(24.212);
my $phase_offset = $wave_ctl->phase_offset(69.289);
my $leading = $wave_ctl->leading(26.815);

my $buffer = $wave_ctl->pack();
#print "WaveControl buffer length: ",length($buffer),"\n";

my $tsc_ctl = Rinchi::CIGIPP::TerrestrialSurfaceConditionsControl->new();
push @packets,$tsc_ctl;

my $packet_type = $tsc_ctl->packet_type();
my $packet_size = $tsc_ctl->packet_size();
my $region_ident = $tsc_ctl->region_ident(32124);
my $entity_ident = $tsc_ctl->entity_ident(34318);
my $surface_condition_ident = $tsc_ctl->surface_condition_ident(62625);
my $severity = $tsc_ctl->severity(15);
my $scope = $tsc_ctl->scope(Rinchi::CIGIPP->RegionalScope);
my $surface_condition_enable = $tsc_ctl->surface_condition_enable(Rinchi::CIGIPP->Disable);
my $coverage = $tsc_ctl->coverage(174);

my $buffer = $tsc_ctl->pack();
#print "TerrestrialSurfaceConditionsControl buffer length: ",length($buffer),"\n";

my $view_ctl = Rinchi::CIGIPP::ViewControl->new();
push @packets,$view_ctl;

my $packet_type = $view_ctl->packet_type();
my $packet_size = $view_ctl->packet_size();
my $view_ident = $view_ctl->view_ident(11410);
my $group_ident = $view_ctl->group_ident(132);
my $yaw_enable = $view_ctl->yaw_enable(Rinchi::CIGIPP->Enable);
my $pitch_enable = $view_ctl->pitch_enable(Rinchi::CIGIPP->Enable);
my $roll_enable = $view_ctl->roll_enable(Rinchi::CIGIPP->Enable);
my $z_offset_enable = $view_ctl->z_offset_enable(Rinchi::CIGIPP->Disable);
my $y_offset_enable = $view_ctl->y_offset_enable(Rinchi::CIGIPP->Enable);
my $x_offset_enable = $view_ctl->x_offset_enable(Rinchi::CIGIPP->Disable);
my $entity_ident = $view_ctl->entity_ident(22744);
my $x_offset = $view_ctl->x_offset(14.225);
my $y_offset = $view_ctl->y_offset(68.843);
my $z_offset = $view_ctl->z_offset(19.148);
my $roll = $view_ctl->roll(53.063);
my $pitch = $view_ctl->pitch(75.147);
my $yaw = $view_ctl->yaw(45.894);

my $buffer = $view_ctl->pack();
#print "ViewControl buffer length: ",length($buffer),"\n";

my $sensor_ctl = Rinchi::CIGIPP::SensorControl->new();
push @packets,$sensor_ctl;

my $packet_type = $sensor_ctl->packet_type();
my $packet_size = $sensor_ctl->packet_size();
my $view_ident = $sensor_ctl->view_ident(60039);
my $sensor_ident = $sensor_ctl->sensor_ident(64);
my $track_mode = $sensor_ctl->track_mode(Rinchi::CIGIPP->Off);
my $track_white_black = $sensor_ctl->track_white_black(Rinchi::CIGIPP->Black);
my $automatic_gain_enable = $sensor_ctl->automatic_gain_enable(Rinchi::CIGIPP->Disable);
my $line_by_line_dropout_enable = $sensor_ctl->line_by_line_dropout_enable(Rinchi::CIGIPP->Enable);
my $polarity = $sensor_ctl->polarity(Rinchi::CIGIPP->BlackHot);
my $sensor_on_off = $sensor_ctl->sensor_on_off(Rinchi::CIGIPP->Off);
my $response_type = $sensor_ctl->response_type(Rinchi::CIGIPP->NormalSRT);
my $gain = $sensor_ctl->gain(54.14);
my $level = $sensor_ctl->level(11.886);
my $ac_coupling = $sensor_ctl->ac_coupling(46.118);
my $noise = $sensor_ctl->noise(36.755);

my $buffer = $sensor_ctl->pack();
#print "SensorControl buffer length: ",length($buffer),"\n";

my $mt_ctl = Rinchi::CIGIPP::MotionTrackerControl->new();
push @packets,$mt_ctl;

my $packet_type = $mt_ctl->packet_type();
my $packet_size = $mt_ctl->packet_size();
my $view_ident = $mt_ctl->view_ident(21903);
my $tracker_ident = $mt_ctl->tracker_ident(15);
my $yaw_enable = $mt_ctl->yaw_enable(Rinchi::CIGIPP->Disable);
my $pitch_enable = $mt_ctl->pitch_enable(Rinchi::CIGIPP->Enable);
my $roll_enable = $mt_ctl->roll_enable(Rinchi::CIGIPP->Disable);
my $z_enable = $mt_ctl->z_enable(Rinchi::CIGIPP->Disable);
my $y_enable = $mt_ctl->y_enable(Rinchi::CIGIPP->Enable);
my $x_enable = $mt_ctl->x_enable(Rinchi::CIGIPP->Enable);
my $boresight_enable = $mt_ctl->boresight_enable(Rinchi::CIGIPP->Enable);
my $tracker_enable = $mt_ctl->tracker_enable(Rinchi::CIGIPP->Disable);
my $view_group = $mt_ctl->view_group(Rinchi::CIGIPP->View);

my $buffer = $mt_ctl->pack();
#print "MotionTrackerControl buffer length: ",length($buffer),"\n";

my $erm_def = Rinchi::CIGIPP::EarthReferenceModelDefinition->new();
push @packets,$erm_def;

my $packet_type = $erm_def->packet_type();
my $packet_size = $erm_def->packet_size();
my $custom_erm = $erm_def->custom_erm(Rinchi::CIGIPP->Enable);
my $equatorial_radius = $erm_def->equatorial_radius(6.458);
my $flattening = $erm_def->flattening(32.413);

my $buffer = $erm_def->pack();
#print "EarthReferenceModelDefinition buffer length: ",length($buffer),"\n";

my $traj_def = Rinchi::CIGIPP::TrajectoryDefinition->new();
push @packets,$traj_def;

my $packet_type = $traj_def->packet_type();
my $packet_size = $traj_def->packet_size();
my $entity_ident = $traj_def->entity_ident(55021);
my $x_acceleration = $traj_def->x_acceleration(60.29);
my $y_acceleration = $traj_def->y_acceleration(33.53);
my $z_acceleration = $traj_def->z_acceleration(3.749);
my $retardation_rate = $traj_def->retardation_rate(5.483);
my $terminal_velocity = $traj_def->terminal_velocity(84.799);

my $buffer = $traj_def->pack();
#print "TrajectoryDefinition buffer length: ",length($buffer),"\n";

my $view_def = Rinchi::CIGIPP::ViewDefinition->new();
push @packets,$view_def;

my $packet_type = $view_def->packet_type();
my $packet_size = $view_def->packet_size();
my $view_ident = $view_def->view_ident(6573);
my $group_ident = $view_def->group_ident(245);
my $mirror_mode = $view_def->mirror_mode(Rinchi::CIGIPP->None);
my $bottom_enable = $view_def->bottom_enable(Rinchi::CIGIPP->Disable);
my $top_enable = $view_def->top_enable(Rinchi::CIGIPP->Disable);
my $right_enable = $view_def->right_enable(Rinchi::CIGIPP->Disable);
my $left_enable = $view_def->left_enable(Rinchi::CIGIPP->Disable);
my $far_enable = $view_def->far_enable(Rinchi::CIGIPP->Disable);
my $near_enable = $view_def->near_enable(Rinchi::CIGIPP->Disable);
my $view_type = $view_def->view_type(2);
my $reorder = $view_def->reorder(Rinchi::CIGIPP->NoReorder);
my $projection_type = $view_def->projection_type(Rinchi::CIGIPP->Perspective);
my $pixel_replication_mode = $view_def->pixel_replication_mode(Rinchi::CIGIPP->None);
my $near = $view_def->near(36.544);
my $far = $view_def->far(79.657);
my $left = $view_def->left(8.335);
my $right = $view_def->right(1.447);
my $top = $view_def->top(12.453);
my $bottom = $view_def->bottom(36.497);

my $buffer = $view_def->pack();
#print "ViewDefinition buffer length: ",length($buffer),"\n";

my $cds_def = Rinchi::CIGIPP::CollisionDetectionSegmentDefinition->new();
push @packets,$cds_def;

my $packet_type = $cds_def->packet_type();
my $packet_size = $cds_def->packet_size();
my $entity_ident = $cds_def->entity_ident(58547);
my $segment_ident = $cds_def->segment_ident(64);
my $segment_enable = $cds_def->segment_enable(Rinchi::CIGIPP->Disable);
my $x1 = $cds_def->x1(27.907);
my $y1 = $cds_def->y1(79.193);
my $z1 = $cds_def->z1(1.157);
my $x2 = $cds_def->x2(42.937);
my $y2 = $cds_def->y2(47.855);
my $z2 = $cds_def->z2(49.825);
my $material_mask = $cds_def->material_mask(38021);

my $buffer = $cds_def->pack();
#print "CollisionDetectionSegmentDefinition buffer length: ",length($buffer),"\n";

my $cdv_def = Rinchi::CIGIPP::CollisionDetectionVolumeDefinition->new();
push @packets,$cdv_def;

my $packet_type = $cdv_def->packet_type();
my $packet_size = $cdv_def->packet_size();
my $entity_ident = $cdv_def->entity_ident(56515);
my $volume_ident = $cdv_def->volume_ident(33);
my $volume_type = $cdv_def->volume_type(Rinchi::CIGIPP->Sphere);
my $volume_enable = $cdv_def->volume_enable(Rinchi::CIGIPP->Enable);
my $x = $cdv_def->x(42.227);
my $y = $cdv_def->y(17.683);
my $z = $cdv_def->z(61.995);
my $radius = $cdv_def->radius(42.354);
my $height = $cdv_def->height(82.136);
my $width = $cdv_def->width(62.861);
my $depth = $cdv_def->depth(56.607);
my $roll = $cdv_def->roll(72.09);
my $pitch = $cdv_def->pitch(50.275);
my $yaw = $cdv_def->yaw(10.898);

my $buffer = $cdv_def->pack();
#print "CollisionDetectionVolumeDefinition buffer length: ",length($buffer),"\n";

my $hgt_rqst = Rinchi::CIGIPP::HAT_HOTRequest->new();
push @packets,$hgt_rqst;

my $packet_type = $hgt_rqst->packet_type();
my $packet_size = $hgt_rqst->packet_size();
my $request_ident = $hgt_rqst->request_ident(13384);
my $coordinate_system = $hgt_rqst->coordinate_system(Rinchi::CIGIPP->GeodeticCS);
my $request_type = $hgt_rqst->request_type(Rinchi::CIGIPP->HeightOfTerrain);
my $update_period = $hgt_rqst->update_period(156);
my $entity_ident = $hgt_rqst->entity_ident(48093);
my $latitude = $hgt_rqst->latitude(69.592);
my $x_offset = $hgt_rqst->x_offset(17.607);
my $longitude = $hgt_rqst->longitude(68.523);
my $y_offset = $hgt_rqst->y_offset(20.113);
my $altitude = $hgt_rqst->altitude(43.044);
my $z_offset = $hgt_rqst->z_offset(23.044);

my $buffer = $hgt_rqst->pack();
#print "HAT_HOTRequest buffer length: ",length($buffer),"\n";

my $loss_rqst = Rinchi::CIGIPP::LineOfSightSegmentRequest->new();
push @packets,$loss_rqst;

my $packet_type = $loss_rqst->packet_type();
my $packet_size = $loss_rqst->packet_size();
my $request_ident = $loss_rqst->request_ident(21900);
my $destination_entity_valid = $loss_rqst->destination_entity_valid(Rinchi::CIGIPP->Valid);
my $response_coordinate_system = $loss_rqst->response_coordinate_system(Rinchi::CIGIPP->GeodeticCS);
my $destination_point_coordinate_system = $loss_rqst->destination_point_coordinate_system(Rinchi::CIGIPP->GeodeticCS);
my $source_point_coordinate_system = $loss_rqst->source_point_coordinate_system(Rinchi::CIGIPP->EntityCS);
my $request_type = $loss_rqst->request_type(Rinchi::CIGIPP->BasicLOS);
my $alpha_threshold = $loss_rqst->alpha_threshold(109);
my $source_entity_ident = $loss_rqst->source_entity_ident(49099);
my $source_latitude = $loss_rqst->source_latitude(51.147);
my $source_xoffset = $loss_rqst->source_xoffset(62.907);
my $source_longitude = $loss_rqst->source_longitude(78.025);
my $source_yoffset = $loss_rqst->source_yoffset(54.82);
my $source_altitude = $loss_rqst->source_altitude(58.857);
my $source_zoffset = $loss_rqst->source_zoffset(29.08);
my $destination_latitude = $loss_rqst->destination_latitude(43.842);
my $destination_xoffset = $loss_rqst->destination_xoffset(75.381);
my $destination_longitude = $loss_rqst->destination_longitude(44.992);
my $destination_yoffset = $loss_rqst->destination_yoffset(15.47);
my $destination_altitude = $loss_rqst->destination_altitude(36.503);
my $destination_zoffset = $loss_rqst->destination_zoffset(16.844);
my $material_mask = $loss_rqst->material_mask(52904);
my $update_period = $loss_rqst->update_period(241);
my $destination_entity_ident = $loss_rqst->destination_entity_ident(60143);

my $buffer = $loss_rqst->pack();
#print "LineOfSightSegmentRequest buffer length: ",length($buffer),"\n";

my $losv_rqst = Rinchi::CIGIPP::LineOfSightVectorRequest->new();
push @packets,$losv_rqst;

my $packet_type = $losv_rqst->packet_type();
my $packet_size = $losv_rqst->packet_size();
my $request_ident = $losv_rqst->request_ident(38090);
my $response_coordinate_system = $losv_rqst->response_coordinate_system(Rinchi::CIGIPP->EntityCS);
my $source_point_coordinate_system = $losv_rqst->source_point_coordinate_system(Rinchi::CIGIPP->GeodeticCS);
my $request_type = $losv_rqst->request_type(Rinchi::CIGIPP->BasicLOS);
my $alpha_threshold = $losv_rqst->alpha_threshold(186);
my $source_entity_ident = $losv_rqst->source_entity_ident(37849);
my $azimuth = $losv_rqst->azimuth(41.692);
my $elevation = $losv_rqst->elevation(53.069);
my $minimum_range = $losv_rqst->minimum_range(8.405);
my $maximum_range = $losv_rqst->maximum_range(66.277);
my $source_latitude = $losv_rqst->source_latitude(54.95);
my $source_xoffset = $losv_rqst->source_xoffset(47.242);
my $source_longitude = $losv_rqst->source_longitude(63.473);
my $source_yoffset = $losv_rqst->source_yoffset(13.438);
my $source_altitude = $losv_rqst->source_altitude(52.653);
my $source_zoffset = $losv_rqst->source_zoffset(14.289);
my $material_mask = $losv_rqst->material_mask(37559);
my $update_period = $losv_rqst->update_period(103);

my $buffer = $losv_rqst->pack();
#print "LineOfSightVectorRequest buffer length: ",length($buffer),"\n";

my $pos_rqst = Rinchi::CIGIPP::PositionRequest->new();
push @packets,$pos_rqst;

$packet_type = $pos_rqst->packet_type();
$packet_size = $pos_rqst->packet_size();
my $object_ident = $pos_rqst->object_ident(43377);
my $articulated_part_ident = $pos_rqst->articulated_part_ident(145);
my $coordinate_system = $pos_rqst->coordinate_system(Rinchi::CIGIPP->ParentEntityCS);
my $object_class = $pos_rqst->object_class(Rinchi::CIGIPP->EntityOC);
my $update_mode = $pos_rqst->update_mode(0);

my $buffer = $pos_rqst->pack();
#print "PositionRequest buffer length: ",length($buffer),"\n";

my $ec_rqst = Rinchi::CIGIPP::EnvironmentalConditionsRequest->new();
push @packets,$ec_rqst;

my $packet_type = $ec_rqst->packet_type();
my $packet_size = $ec_rqst->packet_size();
my $request_type_ac = $ec_rqst->request_type_ac(1);
my $request_type_wc = $ec_rqst->request_type_wc(0);
my $request_type_tsc = $ec_rqst->request_type_tsc(1);
my $request_type_msc = $ec_rqst->request_type_msc(0);
my $request_ident = $ec_rqst->request_ident(167);
my $latitude = $ec_rqst->latitude(28.347);
my $longitude = $ec_rqst->longitude(82.085);
my $altitude = $ec_rqst->altitude(38.01);

my $buffer = $ec_rqst->pack();
#print "EnvironmentalConditionsRequest buffer length: ",length($buffer),"\n";

my $sym_surf = Rinchi::CIGIPP::SymbolSurfaceDefinition->new();
push @packets,$sym_surf;

$packet_type = $sym_surf->packet_type();
$packet_size = $sym_surf->packet_size();
my $surface_ident = $sym_surf->surface_ident(35085);
my $perspective_growth_enable = $sym_surf->perspective_growth_enable(Rinchi::CIGIPP->Enabled);
my $billboard = $sym_surf->billboard(Rinchi::CIGIPP->Billboard);
my $attach_type = $sym_surf->attach_type(Rinchi::CIGIPP->ViewAT);
my $surface_state = $sym_surf->surface_state(Rinchi::CIGIPP->DestroyedSS);
$entity_ident = $sym_surf->entity_ident(47752);
$view_ident = $sym_surf->view_ident(58180);
$x_offset = $sym_surf->x_offset(40.156);
$left = $sym_surf->left(30.873);
$y_offset = $sym_surf->y_offset(36.278);
$right = $sym_surf->right(65.423);
$z_offset = $sym_surf->z_offset(64.092);
$top = $sym_surf->top(30.89);
$yaw = $sym_surf->yaw(0.109);
$bottom = $sym_surf->bottom(5.179);
$pitch = $sym_surf->pitch(80.979);
$roll = $sym_surf->roll(61.448);
my $width = $sym_surf->width(83.426);
my $height = $sym_surf->height(47.941);
my $min_u = $sym_surf->min_u(31.315);
my $max_u = $sym_surf->max_u(53.721);
my $min_v = $sym_surf->min_v(16.873);
my $max_v = $sym_surf->max_v(34.874);

my $buffer = $sym_surf->pack();
#print "SymbolSurfaceDefinition buffer length: ",length($buffer),"\n";

my $sym_text = Rinchi::CIGIPP::SymbolTextDefinition->new();
push @packets,$sym_text;

$packet_type = $sym_text->packet_type();
$packet_size = $sym_text->packet_size();
my $symbol_ident = $sym_text->symbol_ident(29183);
my $orientation = $sym_text->orientation(Rinchi::CIGIPP->LeftToRight);
my $alignment = $sym_text->alignment(Rinchi::CIGIPP->TopCenter);
my $font_ident = $sym_text->font_ident(Rinchi::CIGIPP->IGDefault);
my $font_size = $sym_text->font_size(83.754);
my $text = $sym_text->text("Hello World!");

my $buffer = $sym_text->pack();
#print "SymbolTextDefinition buffer length: ",length($buffer),",",$sym_text->packet_size(),"\n";

my $sym_circ = Rinchi::CIGIPP::SymbolCircleDefinition->new();
push @packets,$sym_circ;

$packet_type = $sym_circ->packet_type();
$packet_size = $sym_circ->packet_size();
$symbol_ident = $sym_circ->symbol_ident(64120);
my $drawing_style = $sym_circ->drawing_style(Rinchi::CIGIPP->DrawingStyleLine);
my $stipple_pattern = $sym_circ->stipple_pattern(0x1F1F);
my $line_width = $sym_circ->line_width(1.125);
my $stipple_pattern_length = $sym_circ->stipple_pattern_length(21.99115);

my $circle0 = Rinchi::CIGIPP::SymbolCircle->new();
$sym_circ->circle(0, $circle0);
$circle0->center_u(0.0);
$circle0->center_v(0.0);
$circle0->radius(7.0);
$circle0->inner_radius(4.0);
$circle0->start_angle(45);
$circle0->end_angle(135);

my $circle1 = Rinchi::CIGIPP::SymbolCircle->new();
$sym_circ->circle(1, $circle1);
$circle1->center_u(0.0);
$circle1->center_v(0.0);
$circle1->radius(10.0);
$circle1->inner_radius(7.0);
$circle1->start_angle(135);
$circle1->end_angle(45);

my $buffer = $sym_circ->pack();
#print "SymbolCircleDefinition buffer length: ",length($buffer),",",$sym_circ->packet_size(),"\n";

my $sym_line = Rinchi::CIGIPP::SymbolLineDefinition->new();
push @packets,$sym_line;

$packet_type = $sym_line->packet_type();
$packet_size = $sym_line->packet_size();
$symbol_ident = $sym_line->symbol_ident(19346);
my $primitive_type = $sym_line->primitive_type(Rinchi::CIGIPP->TriangleStrip);
$stipple_pattern = $sym_line->stipple_pattern(36348);
$line_width = $sym_line->line_width(49.086);
$stipple_pattern_length = $sym_line->stipple_pattern_length(16.425);

my $vertex0 = Rinchi::CIGIPP::SymbolVertex->new();
$sym_line->vertex(0, $vertex0);
$vertex0->vertex_u(0.0);
$vertex0->vertex_v(0.0);

my $vertex1 = Rinchi::CIGIPP::SymbolVertex->new();
$sym_line->vertex(1, $vertex1);
$vertex1->vertex_u(10.0);
$vertex1->vertex_v(0.0);

my $vertex2 = Rinchi::CIGIPP::SymbolVertex->new();
$sym_line->vertex(2, $vertex2);
$vertex2->vertex_u(10.0);
$vertex2->vertex_v(10.0);

my $vertex3 = Rinchi::CIGIPP::SymbolVertex->new();
$sym_line->vertex(3, $vertex3);
$vertex3->vertex_u(20.0);
$vertex3->vertex_v(10.0);

my $buffer = $sym_line->pack();
#print "SymbolLineDefinition buffer length: ",length($buffer),",",$sym_line->packet_size(),"\n";

my $sym_clone = Rinchi::CIGIPP::SymbolClone->new();
push @packets,$sym_clone;

$packet_type = $sym_clone->packet_type();
$packet_size = $sym_clone->packet_size();
$symbol_ident = $sym_clone->symbol_ident(41795);
my $source_type = $sym_clone->source_type(Rinchi::CIGIPP->Symbol);
my $source_ident = $sym_clone->source_ident(42236);

my $buffer = $sym_clone->pack();
#print "SymbolClone buffer length: ",length($buffer),"\n";

my $sym_ctl = Rinchi::CIGIPP::SymbolControl->new();
push @packets,$sym_ctl;

$packet_type = $sym_ctl->packet_type();
$packet_size = $sym_ctl->packet_size();
$symbol_ident = $sym_ctl->symbol_ident(44253);
my $inherit_color = $sym_ctl->inherit_color(Rinchi::CIGIPP->NotInherited);
my $flash_control = $sym_ctl->flash_control(Rinchi::CIGIPP->RestartFlash);
$attach_state = $sym_ctl->attach_state(Rinchi::CIGIPP->Attach);
my $symbol_state = $sym_ctl->symbol_state(Rinchi::CIGIPP->Visible);
my $parent_symbol_ident = $sym_ctl->parent_symbol_ident(18590);
$surface_ident = $sym_ctl->surface_ident(34382);
my $layer = $sym_ctl->layer(40);
my $flash_duty_cycle = $sym_ctl->flash_duty_cycle(84);
my $flash_period = $sym_ctl->flash_period(16.565);
my $position_u = $sym_ctl->position_u(77.791);
my $position_v = $sym_ctl->position_v(26.596);
$rotation = $sym_ctl->rotation(36.297);
my $red = $sym_ctl->red(61);
my $green = $sym_ctl->green(0);
my $blue = $sym_ctl->blue(203);
$alpha = $sym_ctl->alpha(39);
my $scale_u = $sym_ctl->scale_u(60.944);
my $scale_v = $sym_ctl->scale_v(75.746);

my $buffer = $sym_ctl->pack();
#print "SymbolControl buffer length: ",length($buffer),"\n";

my $ssym_ctl = Rinchi::CIGIPP::ShortSymbolControl->new();
push @packets,$ssym_ctl;

$packet_type = $ssym_ctl->packet_type();
$packet_size = $ssym_ctl->packet_size();
$symbol_ident = $ssym_ctl->symbol_ident(48088);
$inherit_color = $ssym_ctl->inherit_color(Rinchi::CIGIPP->NotInherited);
$flash_control = $ssym_ctl->flash_control(Rinchi::CIGIPP->RestartFlash);
$attach_state = $ssym_ctl->attach_state(Rinchi::CIGIPP->Detach);
$symbol_state = $ssym_ctl->symbol_state(Rinchi::CIGIPP->Hidden);
my $attribute_select1 = $ssym_ctl->attribute_select1(Rinchi::CIGIPP->None);
my $attribute_select2 = $ssym_ctl->attribute_select2(Rinchi::CIGIPP->None);
my $attribute_value1 = $ssym_ctl->attribute_value1(8789);
my $attribute_value2 = $ssym_ctl->attribute_value2(27011);

my $buffer = $ssym_ctl->pack();
#print "ShortSymbolControl buffer length: ",length($buffer),"\n";

my $start_of_frame = Rinchi::CIGIPP::StartOfFrame->new();
push @packets,$start_of_frame;

$packet_type = $start_of_frame->packet_type();
$packet_size = $start_of_frame->packet_size();
$major_version = $start_of_frame->major_version();
$database_number = $start_of_frame->database_number(65);
my $ig_status = $start_of_frame->ig_status(190);
$minor_version = $start_of_frame->minor_version();
my $earth_reference_model = $start_of_frame->earth_reference_model(Rinchi::CIGIPP->HostDefined);
$timestamp_valid = $start_of_frame->timestamp_valid(Rinchi::CIGIPP->Invalid);
$ig_mode = $start_of_frame->ig_mode(Rinchi::CIGIPP->Reset);
$magic_number = $start_of_frame->magic_number();
my $ig_frame_number = $start_of_frame->ig_frame_number(44786);
$timestamp = $start_of_frame->timestamp(37374);
my $last_host_frame_number = $start_of_frame->last_host_frame_number(55338);

my $buffer = $start_of_frame->pack();
#print "StartOfFrame buffer length: ",length($buffer),"\n";

my $hgt_resp = Rinchi::CIGIPP::HAT_HOTResponse->new();
push @packets,$hgt_resp;

$packet_type = $hgt_resp->packet_type();
$packet_size = $hgt_resp->packet_size();
my $response_ident = $hgt_resp->response_ident(47273);
my $host_frame_number_lsn = $hgt_resp->host_frame_number_lsn(13);
$response_type = $hgt_resp->response_type(Rinchi::CIGIPP->HeightAboveTerrain);
my $valid = $hgt_resp->valid(Rinchi::CIGIPP->Invalid);
$height = $hgt_resp->height(51.413);

my $buffer = $hgt_resp->pack();
#print "HAT_HOTResponse buffer length: ",length($buffer),"\n";

my $hgt_xresp = Rinchi::CIGIPP::HAT_HOTExtendedResponse->new();
push @packets,$hgt_xresp;

$packet_type = $hgt_xresp->packet_type();
$packet_size = $hgt_xresp->packet_size();
$response_ident = $hgt_xresp->response_ident(56733);
$host_frame_number_lsn = $hgt_xresp->host_frame_number_lsn(4);
$valid = $hgt_xresp->valid(Rinchi::CIGIPP->Invalid);
my $height_above_terrain = $hgt_xresp->height_above_terrain(86.966);
my $height_of_terrain = $hgt_xresp->height_of_terrain(74.029);
my $material_code = $hgt_xresp->material_code(53788);
my $normal_vector_azimuth = $hgt_xresp->normal_vector_azimuth(3.08);
my $normal_vector_elevation = $hgt_xresp->normal_vector_elevation(82.952);

my $buffer = $hgt_xresp->pack();
#print "HAT_HOTExtendedResponse buffer length: ",length($buffer),"\n";

my $los_resp = Rinchi::CIGIPP::LineOfSightResponse->new();
push @packets,$los_resp;

$packet_type = $los_resp->packet_type();
$packet_size = $los_resp->packet_size();
$request_ident = $los_resp->request_ident(23176);
$host_frame_number_lsn = $los_resp->host_frame_number_lsn(15);
my $visible = $los_resp->visible(Rinchi::CIGIPP->Occluded);
my $entity_ident_valid = $los_resp->entity_ident_valid(Rinchi::CIGIPP->Invalid);
$valid = $los_resp->valid(Rinchi::CIGIPP->Invalid);
my $response_count = $los_resp->response_count(68);
$entity_ident = $los_resp->entity_ident(9383);
my $range = $los_resp->range(45.403);

my $buffer = $los_resp->pack();
#print "LineOfSightResponse buffer length: ",length($buffer),"\n";

my $los_xresp = Rinchi::CIGIPP::LineOfSightExtendedResponse->new();
push @packets,$los_xresp;

$packet_type = $los_xresp->packet_type();
$packet_size = $los_xresp->packet_size();
$request_ident = $los_xresp->request_ident(57);
$host_frame_number_lsn = $los_xresp->host_frame_number_lsn(4);
$visible = $los_xresp->visible(Rinchi::CIGIPP->Occluded);
my $range_valid = $los_xresp->range_valid(Rinchi::CIGIPP->Invalid);
$entity_ident_valid = $los_xresp->entity_ident_valid(Rinchi::CIGIPP->Invalid);
$valid = $los_xresp->valid(Rinchi::CIGIPP->Valid);
$response_count = $los_xresp->response_count(217);
$entity_ident = $los_xresp->entity_ident(41000);
$range = $los_xresp->range(17.74);
$latitude = $los_xresp->latitude(19.293);
$x_offset = $los_xresp->x_offset(14.649);
$longitude = $los_xresp->longitude(57.589);
$y_offset = $los_xresp->y_offset(47.628);
$altitude = $los_xresp->altitude(9.33);
$z_offset = $los_xresp->z_offset(43.407);
$red = $los_xresp->red(89);
$green = $los_xresp->green(122);
$blue = $los_xresp->blue(160);
$alpha = $los_xresp->alpha(242);
$material_code = $los_xresp->material_code(22573);
$normal_vector_azimuth = $los_xresp->normal_vector_azimuth(35.653);
$normal_vector_elevation = $los_xresp->normal_vector_elevation(41.678);

my $buffer = $los_xresp->pack();
#print "LineOfSightExtendedResponse buffer length: ",length($buffer),"\n";

my $sensor_resp = Rinchi::CIGIPP::SensorResponse->new();
push @packets,$sensor_resp;

$packet_type = $sensor_resp->packet_type();
$packet_size = $sensor_resp->packet_size();
$view_ident = $sensor_resp->view_ident(7825);
$sensor_ident = $sensor_resp->sensor_ident(71);
my $sensor_status = $sensor_resp->sensor_status(Rinchi::CIGIPP->Tracking);
my $gate_xsize = $sensor_resp->gate_xsize(21687);
my $gate_ysize = $sensor_resp->gate_ysize(11524);
my $gate_xposition = $sensor_resp->gate_xposition(53.246);
my $gate_yposition = $sensor_resp->gate_yposition(75.892);
$host_frame_number = $sensor_resp->host_frame_number(19728);

my $buffer = $sensor_resp->pack();
#print "SensorResponse buffer length: ",length($buffer),"\n";

my $sensor_xresp = Rinchi::CIGIPP::SensorExtendedResponse->new();
push @packets,$sensor_xresp;

$packet_type = $sensor_xresp->packet_type();
$packet_size = $sensor_xresp->packet_size();
$view_ident = $sensor_xresp->view_ident(15496);
$sensor_ident = $sensor_xresp->sensor_ident(42);
$entity_ident_valid = $sensor_xresp->entity_ident_valid(Rinchi::CIGIPP->Valid);
$sensor_status = $sensor_xresp->sensor_status(Rinchi::CIGIPP->Invalid);
$entity_ident = $sensor_xresp->entity_ident(64212);
$gate_xsize = $sensor_xresp->gate_xsize(22491);
$gate_ysize = $sensor_xresp->gate_ysize(15321);
$gate_xposition = $sensor_xresp->gate_xposition(9.495);
$gate_yposition = $sensor_xresp->gate_yposition(56.78);
$host_frame_number = $sensor_xresp->host_frame_number(22764);
my $track_point_latitude = $sensor_xresp->track_point_latitude(75.221);
my $track_point_longitude = $sensor_xresp->track_point_longitude(4.123);
my $track_point_altitude = $sensor_xresp->track_point_altitude(68.142);

my $buffer = $sensor_xresp->pack();
#print "SensorExtendedResponse buffer length: ",length($buffer),"\n";

my $pos_resp = Rinchi::CIGIPP::PositionResponse->new();
push @packets,$pos_resp;

$packet_type = $pos_resp->packet_type();
$packet_size = $pos_resp->packet_size();
$object_ident = $pos_resp->object_ident(8699);
$articulated_part_ident = $pos_resp->articulated_part_ident(116);
$coordinate_system = $pos_resp->coordinate_system(Rinchi::CIGIPP->ParentEntityCS);
$object_class = $pos_resp->object_class(Rinchi::CIGIPP->ArticulatedPartOC);
$latitude = $pos_resp->latitude(27.645);
$x_offset = $pos_resp->x_offset(26.409);
$longitude = $pos_resp->longitude(55.496);
$y_offset = $pos_resp->y_offset(48.675);
$altitude = $pos_resp->altitude(24.851);
$z_offset = $pos_resp->z_offset(47.335);
$roll = $pos_resp->roll(8.422);
$pitch = $pos_resp->pitch(84.2);
$yaw = $pos_resp->yaw(42.084);

my $buffer = $pos_resp->pack();
#print "PositionResponse buffer length: ",length($buffer),"\n";

my $wthr_resp = Rinchi::CIGIPP::WeatherConditionsResponse->new();
push @packets,$wthr_resp;

$packet_type = $wthr_resp->packet_type();
$packet_size = $wthr_resp->packet_size();
$request_ident = $wthr_resp->request_ident(41);
$humidity = $wthr_resp->humidity(45);
$air_temperature = $wthr_resp->air_temperature(76.992);
$visibility_range = $wthr_resp->visibility_range(36.303);
$horizontal_wind_speed = $wthr_resp->horizontal_wind_speed(47.571);
$vertical_wind_speed = $wthr_resp->vertical_wind_speed(45.084);
$wind_direction = $wthr_resp->wind_direction(0.137);
$barometric_pressure = $wthr_resp->barometric_pressure(89.194);

my $buffer = $wthr_resp->pack();
#print "WeatherConditionsResponse buffer length: ",length($buffer),"\n";

my $ac_resp = Rinchi::CIGIPP::AerosolConcentrationResponse->new();
push @packets,$ac_resp;

$packet_type = $ac_resp->packet_type();
$packet_size = $ac_resp->packet_size();
$request_ident = $ac_resp->request_ident(38);
$layer_ident = $ac_resp->layer_ident(78);
$aerosol_concentration = $ac_resp->aerosol_concentration(59.538);

my $buffer = $ac_resp->pack();
#print "AerosolConcentrationResponse buffer length: ",length($buffer),"\n";

my $msc_resp = Rinchi::CIGIPP::MaritimeSurfaceConditionsResponse->new();
push @packets,$msc_resp;

$packet_type = $msc_resp->packet_type();
$packet_size = $msc_resp->packet_size();
$request_ident = $msc_resp->request_ident(122);
$sea_surface_height = $msc_resp->sea_surface_height(9.874);
$surface_water_temperature = $msc_resp->surface_water_temperature(82.083);
$surface_clarity = $msc_resp->surface_clarity(8.774);

my $buffer = $msc_resp->pack();
#print "MaritimeSurfaceConditionsResponse buffer length: ",length($buffer),"\n";

my $tsc_resp = Rinchi::CIGIPP::TerrestrialSurfaceConditionsResponse->new();
push @packets,$tsc_resp;

$packet_type = $tsc_resp->packet_type();
$packet_size = $tsc_resp->packet_size();
$request_ident = $tsc_resp->request_ident(208);
$surface_condition_ident = $tsc_resp->surface_condition_ident(53038);

my $buffer = $tsc_resp->pack();
#print "TerrestrialSurfaceConditionsResponse buffer length: ",length($buffer),"\n";

my $cds_ntc = Rinchi::CIGIPP::CollisionDetectionSegmentNotification->new();
push @packets,$cds_ntc;

$packet_type = $cds_ntc->packet_type();
$packet_size = $cds_ntc->packet_size();
$entity_ident = $cds_ntc->entity_ident(22708);
$segment_ident = $cds_ntc->segment_ident(165);
my $collision_type = $cds_ntc->collision_type(Rinchi::CIGIPP->CollisionEntity);
my $contacted_entity_ident = $cds_ntc->contacted_entity_ident(26345);
$material_code = $cds_ntc->material_code(56614);
my $intersection_distance = $cds_ntc->intersection_distance(10.493);

my $buffer = $cds_ntc->pack();
#print "CollisionDetectionSegmentNotification buffer length: ",length($buffer),"\n";

my $cdv_ntc = Rinchi::CIGIPP::CollisionDetectionVolumeNotification->new();
push @packets,$cdv_ntc;

$packet_type = $cdv_ntc->packet_type();
$packet_size = $cdv_ntc->packet_size();
$entity_ident = $cdv_ntc->entity_ident(16373);
$volume_ident = $cdv_ntc->volume_ident(83);
$collision_type = $cdv_ntc->collision_type(Rinchi::CIGIPP->CollisionEntity);
$contacted_entity_ident = $cdv_ntc->contacted_entity_ident(36408);
my $contacted_volume_ident = $cdv_ntc->contacted_volume_ident(60);

my $buffer = $cdv_ntc->pack();
#print "CollisionDetectionVolumeNotification buffer length: ",length($buffer),"\n";

my $stop_ntc = Rinchi::CIGIPP::AnimationStopNotification->new();
push @packets,$stop_ntc;

$packet_type = $stop_ntc->packet_type();
$packet_size = $stop_ntc->packet_size();
$entity_ident = $stop_ntc->entity_ident(44464);

my $buffer = $stop_ntc->pack();
#print "AnimationStopNotification buffer length: ",length($buffer),"\n";

my $evt_ntc = Rinchi::CIGIPP::EventNotification->new();
push @packets,$evt_ntc;

$packet_type = $evt_ntc->packet_type();
$packet_size = $evt_ntc->packet_size();
my $event_ident = $evt_ntc->event_ident(37952);
my $event_data1 = $evt_ntc->event_data1(285);
my $event_data2 = $evt_ntc->event_data2(36545);
my $event_data3 = $evt_ntc->event_data3(12715);

my $buffer = $evt_ntc->pack();
#print "EventNotification buffer length: ",length($buffer),"\n";

my $ig_msg = Rinchi::CIGIPP::ImageGeneratorMessage->new();
push @packets,$ig_msg;

$packet_type = $ig_msg->packet_type();
$packet_size = $ig_msg->packet_size();
my $message_ident = $ig_msg->message_ident(32020);
my $message = $ig_msg->message('Error 1234');

my $buffer = $ig_msg->pack();
#print "ImageGeneratorMessage buffer length: ",length($buffer),"\n";

#my $cigi = Rinchi::CIGIPP->new();
#my $hdlr = Rinchi::CIGIPP::DefaultHandler->new();
#my @hp = %{$hdlr->get_handlers()};
#$cigi->setHandlers(@hp);

#my $msg_no = 1;
#$cigi->write_message_to_file(\@packets,"message$msg_no.cigi");
#$cigi->dispatch_packets(\@packets,1);
#my $messages = $cigi->scan_file("message$msg_no.cigi");
#foreach $message (@{$messages}) {
#  $msg_no++;
#  $cigi->write_message_to_file($message,"message$msg_no.cigi");
#  $cigi->dispatch_packets($message,$msg_no);
##  $cigi->send_message($message,'127.0.0.1',8021);
##  $cigi->wait_for_message(8022);
#}
#$msg_no++;
#$cigi->write_messages_to_file($messages,"message$msg_no.cigi");
##$cigi->send_message([$ig_ctl,$ent_ctl],'127.0.0.1',8021);
##$cigi->wait_for_message(8022);
##$cigi->send_message([],'127.0.0.1',8021);

