package Monitoring::GLPlugin::SNMP::MibsAndOids::ELTEXMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ELTEX-MIB'} = {
  url => '',
  name => 'ELTEX-MIB',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ELTEX-MIB'} = {
# The table of power supply status maintained by the environmental monitor card.
  'eltexPowerSupplyTable' => '1.3.6.1.4.1.89.83.1.2',
# An entry in the power supply status table, representing the status of the
# associated power supply maintained by the environmental monitor card.
  'eltexPowerSupplyEntry' => '1.3.6.1.4.1.89.83.1.2.1',
# An entry in the power supply status table, representing the status of the
# associated power supply maintained by the environmental monitor card.
  'eltexPowerSupplyId' => '1.3.6.1.4.1.89.83.1.2.1.5',
# Textual description of the power supply being instrumented. This description
# is a short textual label, suitable as a human-sensible identification for the
# rest of the information in the entry.
  'eltexPowerSupplyDescription' => '1.3.6.1.4.1.89.83.1.2.1.2',
# The mandatory state of the power supply being instrumented.eltexSensorDescription
  'eltexPowerSupplyStatus' => '1.3.6.1.4.1.89.83.1.2.1.3',
  'eltexPowerSupplyStatusDefinition' => {
    '1' => 'normal',
    '2' => 'warning',
    '3' => 'critical',
    '4' => 'shutdown',
    '5' => 'notPresent',
    '6' => 'notFunctioning',
  },
  'eltexSensorTable' => '1.3.6.1.4.1.89.83.2.1.1',
# Information about a particular physical sensor. An entry in this table
# describes the present reading of a sensor, the measurement units and scale,
# and sensor operational status. Entries are created in this table by the agent.
# An entry for each physical sensor SHOULD be created at the same time as the
# associated entPhysicalEntry. An entry SHOULD be destroyed if the associated
# entPhysicalEntry is destroyed.
  'eltexSensorEntry' => '1.3.6.1.4.1.89.83.2.1.1.1',
# The number of decimal places of precision in fixed-point sensor values
# returned by the associated entPhySensorValue object. This object SHOULD be set
# to '0' when the associated entPhySensorType value is not a fixed-point
# type: e.g., 'percentRH(9)', 'rpm(10)', 'cmm(11)', or 'truthvalue(12)'. This
# object SHOULD be set by the agent during entry creation, and the value SHOULD
# NOT change during operation.
  'eltexSensorId' => '1.3.6.1.4.1.89.83.2.1.1.1.3',
# A textual description of the data units that should be used in the display of
# entPhySensorValue.
  'eltexSensorDescription' => '1.3.6.1.4.1.89.83.2.1.1.1.6',
# The most recent measurement obtained by the agent for this sensor. To
# correctly interpret the value of this object, the associated entPhySensorType,
# entPhySensorScale, and entPhySensorPrecision objects must also be examined.
  'eltexSensorStatus' => '1.3.6.1.4.1.89.83.2.1.1.1.4',
# The table of fan status maintained by the environmental monitor.
  'eltexFanTable' => '1.3.6.1.4.1.89.83.1.1',
# An entry in the fan status table, representing the status of the associated
# fan maintained by the environmental monitor.
  'eltexFanEntry' => '1.3.6.1.4.1.89.83.1.1.1',
# All fans here with statuses
  'eltexFanId' => '1.3.6.1.4.1.89.83.1.1.1.3',
# Textual description of the fan being instrumented. This description is a short
# textual label, suitable as a human-sensible identification for the rest of the
# information in the entry.
  'eltexFanDescription' => '1.3.6.1.4.1.89.83.1.1.1.2',
# The mandatory state of the fan being instrumented.
  'eltexFanStatus' => '1.3.6.1.4.1.89.83.1.1.1.3',
  'eltexFanStatusDefinition' => {
    '1' => 'normal',
    '5' => 'unknown',
    '6' => 'notPresent',
  },
# Percentage of the device CPU utilization during last second. The value 101 is
# a dummy value, indicating that the CPU utilization was not measured (since
# measurement is disabled or was disabled during last second).
  'eltexCpuUtilisationLastSecond' => '1.3.6.1.4.1.89.1.7.0',
# Percentage of the device CPU utilization during last minute. The value 101 is
# a dummy value, indicating that the CPU utilization was not measured (since
# measurement is disabled or was disabled during last minute).
  'eltexCpuUtilisationOneMinute' => '1.3.6.1.4.1.89.1.8.0',
# Percentage of the device CPU utilization during the last 5 minutes. The value
# 101 is a dummy value, indicating that the CPU utilization was not measured
# (since measurement is disabled or was disabled during last 5 minutes).
  'eltexCpuUtilisationFiveMinutes' => '1.3.6.1.4.1.89.1.9.0',
# Show unit type standalone or stack.
  'eltexStackUnitType' => '1.3.6.1.4.1.89.107.3.0',
# Shows the current number of units in the stack.
  'eltexStackUnitsNumber' => '1.3.6.1.4.1.89.53.8.0'
};
