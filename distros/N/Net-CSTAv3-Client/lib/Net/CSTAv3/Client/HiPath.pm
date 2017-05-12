package Net::CSTAv3::Client::HiPath;

sub CSTA_SystemStatus {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="12">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="2" A="INTEGER">$operation-value</P>
    <C O="9" T="[UNIVERSAL 16]" TL="2" V="3" A="SEQUENCE">
        <P O="11" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">$system-status</P>
    </C O="14" T="[UNIVERSAL 16]" A="SEQUENCE" L="5">
</C O="14" T="[1]" L="14">
END
return $heredoc;
}

sub AARE_apdu {
$heredoc = <<'END';
<C O="0" T="[APPLICATION 1]" TL="2" V="73">
    <C O="2" T="[1]" TL="2" V="7">
        <P O="4" T="[UNIVERSAL 6]" TL="2" V="5" A="OBJECT IDENTIFIER">&#x2b;&#x0c;&#x00;&#x81;&#x5a;</P>
    </C O="11" T="[1]" L="9">
    <C O="11" T="[2]" TL="2" V="3">
        <P O="13" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$result</P>
    </C O="16" T="[2]" L="5">
    <C O="16" T="[3]" TL="2" V="5">
        <C O="18" T="[1]" TL="2" V="3">
            <P O="20" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$result-source-diagnostic</P>
        </C O="23" T="[1]" L="5">
    </C O="23" T="[3]" L="7">
    <P O="23" T="[8]" TL="2" V="$responder-acse-requirements_length">$responder-acse-requirements</P>
    <C O="27" T="[10]" TL="2" V="33">
        <C O="29" T="[2]" TL="2" V="31">
            <C O="31" T="[0]" TL="2" V="29">
                <C O="33" T="[1]" TL="2" V="27">
                    <P O="35" T="[UNIVERSAL 4]" TL="2" V="$aps-stamp_length" A="OCTET STRING">$aps-stamp</P>
                    <P O="53" T="[UNIVERSAL 4]" TL="2" V="$system-version_length" A="OCTET STRING">$system-version</P>
                </C O="62" T="[1]" L="29">
            </C O="62" T="[0]" L="31">
        </C O="62" T="[2]" L="33">
    </C O="62" T="[10]" L="35">
    <C O="62" T="[30]" TL="2" V="11">
        <C O="64" T="[UNIVERSAL 8]" TL="2" V="9" A="EXTERNAL">
            <C O="66" T="[0]" TL="2" V="7">
                <C O="68" T="[0]" TL="2" V="5">
                    <P O="70" T="[UNIVERSAL 3]" TL="2" V="$csta-version_length" A="BIT STRING">$csta-version</P>
                </C O="75" T="[0]" L="7">
            </C O="75" T="[0]" L="9">
        </C O="75" T="[UNIVERSAL 8]" A="EXTERNAL" L="11">
    </C O="75" T="[30]" L="13">
</C O="75" T="[APPLICATION 1]" L="75">
END
return $heredoc;
}

sub CSTA_EventReport_Transferred {
$heredoc = <<'END';
<C O="0" T="[1]" TL="4" V="308">
    <P O="4" T="[UNIVERSAL 2]" TL="2" V="3" A="INTEGER">$invoke-id</P>
    <P O="9" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$operation-value</P>
    <C O="12" T="[UNIVERSAL 16]" TL="4" V="296" A="SEQUENCE">
        <P O="16" T="[APPLICATION 21]" TL="2" V="2">$cross-ref-identifier</P>
        <C O="20" T="[0]" TL="4" V="288">
            <C O="24" T="[17]" TL="4" V="284">
                <C O="28" T="[APPLICATION 11]" TL="2" V="15">
                    <C O="30" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                        <P O="32" T="[0]" TL="2" V="2">$call-id</P>
                        <C O="36" T="[1]" TL="2" V="7">
                            <C O="38" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                <P O="40" T="[0]" TL="2" V="3">$dialing-number</P>
                            </C O="45" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                        </C O="45" T="[1]" L="9">
                    </C O="45" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                </C O="45" T="[APPLICATION 11]" L="17">
                <C O="45" T="[0]" TL="2" V="15">
                    <C O="47" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                        <P O="49" T="[0]" TL="2" V="2">$old-call-id</P>
                        <C O="53" T="[1]" TL="2" V="7">
                            <C O="55" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                <P O="57" T="[0]" TL="2" V="3">$old-call-dialing-number</P>
                            </C O="62" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                        </C O="62" T="[1]" L="9">
                    </C O="62" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                </C O="62" T="[0]" L="17">
                <C O="62" T="[APPLICATION 3]" TL="2" V="7">
                    <C O="64" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="66" T="[0]" TL="2" V="3">$transferring-device</P>
                    </C O="71" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="71" T="[APPLICATION 3]" L="9">
                <C O="71" T="[APPLICATION 3]" TL="2" V="7">
                    <C O="73" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="75" T="[0]" TL="2" V="3">$transferred-to-device</P>
                    </C O="80" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="80" T="[APPLICATION 3]" L="9">
                <C O="80" T="[1]" TL="2" V="118">
                    <C O="82" T="[UNIVERSAL 16]" TL="2" V="67" A="SEQUENCE">
                        <C O="84" T="[0]" TL="2" V="18">
                            <C O="86" T="[APPLICATION 11]" TL="2" V="16">
                                <C O="88" T="[UNIVERSAL 16]" TL="2" V="14" A="SEQUENCE">
                                    <P O="90" T="[0]" TL="2" V="2">$transferred-call-id</P>
                                    <C O="94" T="[1]" TL="2" V="8">
                                        <C O="96" T="[UNIVERSAL 16]" TL="2" V="6" A="SEQUENCE">
                                            <P O="98" T="[0]" TL="2" V="4">$unknown1</P>
                                        </C O="104" T="[UNIVERSAL 16]" A="SEQUENCE" L="8">
                                    </C O="104" T="[1]" L="10">
                                </C O="104" T="[UNIVERSAL 16]" A="SEQUENCE" L="16">
                            </C O="104" T="[APPLICATION 11]" L="18">
                        </C O="104" T="[0]" L="20">
                        <C O="104" T="[1]" TL="2" V="18">
                            <C O="106" T="[APPLICATION 11]" TL="2" V="16">
                                <C O="108" T="[UNIVERSAL 16]" TL="2" V="14" A="SEQUENCE">
                                    <P O="110" T="[0]" TL="2" V="2">&#xb1;&#x64;</P>
                                    <C O="114" T="[1]" TL="2" V="8">
                                        <C O="116" T="[UNIVERSAL 16]" TL="2" V="6" A="SEQUENCE">
                                            <P O="118" T="[0]" TL="2" V="4">&#x37;&#x38;&#x30;&#x36;</P>
                                        </C O="124" T="[UNIVERSAL 16]" A="SEQUENCE" L="8">
                                    </C O="124" T="[1]" L="10">
                                </C O="124" T="[UNIVERSAL 16]" A="SEQUENCE" L="16">
                            </C O="124" T="[APPLICATION 11]" L="18">
                        </C O="124" T="[1]" L="20">
                        <C O="124" T="[2]" TL="2" V="15">
                            <C O="126" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                                <P O="128" T="[0]" TL="2" V="11">$endpoint</P>
                            </C O="141" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                        </C O="141" T="[2]" L="17">
                        <C O="141" T="[3]" TL="2" V="8">
                            <C O="143" T="[UNIVERSAL 16]" TL="2" V="6" A="SEQUENCE">
                                <P O="145" T="[0]" TL="2" V="4">$unknown2</P>
                            </C O="151" T="[UNIVERSAL 16]" A="SEQUENCE" L="8">
                        </C O="151" T="[3]" L="10">
                    </C O="151" T="[UNIVERSAL 16]" A="SEQUENCE" L="69">
                    <C O="151" T="[UNIVERSAL 16]" TL="2" V="47" A="SEQUENCE">
                        <C O="153" T="[0]" TL="2" V="17">
                            <C O="155" T="[APPLICATION 11]" TL="2" V="15">
                                <C O="157" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                                    <P O="159" T="[0]" TL="2" V="2">&#xb1;&#x64;</P>
                                    <C O="163" T="[1]" TL="2" V="7">
                                        <C O="165" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                            <P O="167" T="[0]" TL="2" V="3">&#x32;&#x35;&#x37;</P>
                                        </C O="172" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                                    </C O="172" T="[1]" L="9">
                                </C O="172" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                            </C O="172" T="[APPLICATION 11]" L="17">
                        </C O="172" T="[0]" L="19">
                        <C O="172" T="[1]" TL="2" V="17">
                            <C O="174" T="[APPLICATION 11]" TL="2" V="15">
                                <C O="176" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                                    <P O="178" T="[0]" TL="2" V="2">&#xb1;&#x69;</P>
                                    <C O="182" T="[1]" TL="2" V="7">
                                        <C O="184" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                            <P O="186" T="[0]" TL="2" V="3">&#x32;&#x35;&#x37;</P>
                                        </C O="191" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                                    </C O="191" T="[1]" L="9">
                                </C O="191" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                            </C O="191" T="[APPLICATION 11]" L="17">
                        </C O="191" T="[1]" L="19">
                        <C O="191" T="[2]" TL="2" V="7">
                            <C O="193" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                <P O="195" T="[0]" TL="2" V="3">&#x32;&#x35;&#x37;</P>
                            </C O="200" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                        </C O="200" T="[2]" L="9">
                    </C O="200" T="[UNIVERSAL 16]" A="SEQUENCE" L="49">
                </C O="200" T="[1]" L="120">
                <P O="200" T="[APPLICATION 14]" TL="2" V="1">&#x00;</P>
                <P O="203" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">&#x20;</P>
                <C O="206" T="[7]" TL="2" V="84">
                    <C O="208" T="[UNIVERSAL 16]" TL="2" V="40" A="SEQUENCE">
                        <C O="210" T="[UNIVERSAL 16]" TL="2" V="18" A="SEQUENCE">
                            <P O="212" T="[1]" TL="2" V="16">&#x01;&#x3c;&#xba;&#xaa;&#x50;&#xf7;&#x07;&#x88;&#x01;&#x00;&#x80;&#x00;&#x00;&#x00;&#xb1;&#x6b;</P>
                        </C O="230" T="[UNIVERSAL 16]" A="SEQUENCE" L="20">
                        <C O="230" T="[UNIVERSAL 16]" TL="2" V="18" A="SEQUENCE">
                            <P O="232" T="[1]" TL="2" V="16">&#x04;&#xb4;&#x42;&#x92;&#x50;&#xf7;&#x07;&#x88;&#x01;&#x00;&#x80;&#x00;&#x00;&#x00;&#xb1;&#x64;</P>
                        </C O="250" T="[UNIVERSAL 16]" A="SEQUENCE" L="20">
                    </C O="250" T="[UNIVERSAL 16]" A="SEQUENCE" L="42">
                    <C O="250" T="[UNIVERSAL 16]" TL="2" V="40" A="SEQUENCE">
                        <C O="252" T="[UNIVERSAL 16]" TL="2" V="18" A="SEQUENCE">
                            <P O="254" T="[1]" TL="2" V="16">&#x00;&#x01;&#x30;&#x8a;&#x50;&#xf7;&#x07;&#x88;&#x01;&#x00;&#x80;&#x00;&#x00;&#x00;&#xb1;&#x69;</P>
                        </C O="272" T="[UNIVERSAL 16]" A="SEQUENCE" L="20">
                        <C O="272" T="[UNIVERSAL 16]" TL="2" V="18" A="SEQUENCE">
                            <P O="274" T="[1]" TL="2" V="16">&#x04;&#xb4;&#x42;&#x92;&#x50;&#xf7;&#x07;&#x88;&#x01;&#x00;&#x80;&#x00;&#x00;&#x00;&#xb1;&#x64;</P>
                        </C O="292" T="[UNIVERSAL 16]" A="SEQUENCE" L="20">
                    </C O="292" T="[UNIVERSAL 16]" A="SEQUENCE" L="42">
                </C O="292" T="[7]" L="86">
                <C O="292" T="[APPLICATION 30]" TL="2" V="18">
                    <C O="294" T="[0]" TL="2" V="16">
                        <P O="296" T="[UNIVERSAL 24]" TL="2" V="14" A="GeneralizedTime">$timestamp</P>
                    </C O="312" T="[0]" L="18">
                </C O="312" T="[APPLICATION 30]" L="20">
            </C O="312" T="[17]" L="288">
        </C O="312" T="[0]" L="292">
    </C O="312" T="[UNIVERSAL 16]" A="SEQUENCE" L="300">
</C O="312" T="[1]" L="312">
END
return $heredoc;
}

sub CSTA_EventReport_ConnectionCleared {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="68">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$operation-value</P>
    <C O="8" T="[UNIVERSAL 16]" TL="2" V="60" A="SEQUENCE">
        <P O="10" T="[APPLICATION 21]" TL="2" V="2">$cross-ref-identifier</P>
        <C O="14" T="[0]" TL="2" V="54">
            <C O="16" T="[3]" TL="2" V="52">
                <C O="18" T="[APPLICATION 11]" TL="2" V="15">
                    <C O="20" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                        <P O="22" T="[0]" TL="2" V="2">$call-id</P>
                        <C O="26" T="[1]" TL="2" V="7">
                            <C O="28" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                <P O="30" T="[0]" TL="2" V="3">$dialing-number</P>
                            </C O="35" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                        </C O="35" T="[1]" L="9">
                    </C O="35" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                </C O="35" T="[APPLICATION 11]" L="17">
                <C O="35" T="[APPLICATION 3]" TL="2" V="7">
                    <C O="37" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="39" T="[0]" TL="2" V="3">$releasing-device</P>
                    </C O="44" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="44" T="[APPLICATION 3]" L="9">
                <P O="44" T="[APPLICATION 14]" TL="2" V="1">$connection-info</P>
                <P O="47" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">$cause</P>
                <C O="50" T="[APPLICATION 30]" TL="2" V="18">
                    <C O="52" T="[0]" TL="2" V="16">
                        <P O="54" T="[UNIVERSAL 24]" TL="2" V="14" A="GeneralizedTime">$timestamp</P>
                    </C O="70" T="[0]" L="18">
                </C O="70" T="[APPLICATION 30]" L="20">
            </C O="70" T="[3]" L="54">
        </C O="70" T="[0]" L="56">
    </C O="70" T="[UNIVERSAL 16]" A="SEQUENCE" L="62">
</C O="70" T="[1]" L="70">
END
return $heredoc;
}

sub AARQ_apdu {
$heredoc = <<'END';
<C O="0" T="[APPLICATION 0]" TL="2" V="49">
    <C O="2" T="[1]" TL="2" V="7">
        <P O="4" T="[UNIVERSAL 6]" TL="2" V="5" A="OBJECT IDENTIFIER">&#x2b;&#x0c;&#x00;&#x81;&#x5a;</P>
    </C O="11" T="[1]" L="9">
    <P O="11" T="[10]" TL="2" V="2">&#x06;&#x80;</P>
    <C O="15" T="[12]" TL="2" V="21">
        <C O="17" T="[2]" TL="2" V="19">
            <C O="19" T="[0]" TL="2" V="17">
                <C O="21" T="[0]" TL="2" V="15">
                    <P O="23" T="[UNIVERSAL 4]" TL="2" V="$authentication-name_length" A="OCTET STRING">$authentication-name</P>
                    <P O="31" T="[UNIVERSAL 4]" TL="2" V="$authentication-password_length" A="OCTET STRING">$authentication-password</P>
                </C O="38" T="[0]" L="17">
            </C O="38" T="[0]" L="19">
        </C O="38" T="[2]" L="21">
    </C O="38" T="[12]" L="23">
    <C O="38" T="[30]" TL="2" V="11">
        <C O="40" T="[UNIVERSAL 8]" TL="2" V="9" A="EXTERNAL">
            <C O="42" T="[0]" TL="2" V="7">
                <C O="44" T="[0]" TL="2" V="5">
                    <P O="46" T="[UNIVERSAL 3]" TL="2" V="3" A="BIT STRING">$csta-version</P>
                </C O="51" T="[0]" L="7">
            </C O="51" T="[0]" L="9">
        </C O="51" T="[UNIVERSAL 8]" A="EXTERNAL" L="11">
    </C O="51" T="[30]" L="13">
</C O="51" T="[APPLICATION 0]" L="51">
END
return $heredoc;
}

sub ABRT_apdu {
$heredoc = <<'END';
<C O="0" T="[APPLICATION 4]" TL="2" V="6">
    <P O="2" T="[0]" TL="2" V="1">&#x00;</P>
    <P O="5" T="[1]" TL="2" V="1">&#x01;</P>
</C O="8" T="[APPLICATION 4]" L="8">
END
return $heredoc;
}

sub CSTA_EventReport_Delivered {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="90">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$operation-value</P>
    <C O="8" T="[UNIVERSAL 16]" TL="2" V="82" A="SEQUENCE">
        <P O="10" T="[APPLICATION 21]" TL="2" V="2">$cross-ref-identifier</P>
        <C O="14" T="[0]" TL="2" V="76">
            <C O="16" T="[4]" TL="2" V="74">
                <C O="18" T="[APPLICATION 11]" TL="2" V="15">
                    <C O="20" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                        <P O="22" T="[0]" TL="2" V="2">$call-id</P>
                        <C O="26" T="[1]" TL="2" V="7">
                            <C O="28" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                <P O="30" T="[0]" TL="2" V="3">$dialing-number</P>
                            </C O="35" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                        </C O="35" T="[1]" L="9">
                    </C O="35" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                </C O="35" T="[APPLICATION 11]" L="17">
                <C O="35" T="[APPLICATION 3]" TL="2" V="7">
                    <C O="37" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="39" T="[0]" TL="2" V="3">$alerting-device</P>
                    </C O="44" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="44" T="[APPLICATION 3]" L="9">
                <C O="44" T="[APPLICATION 1]" TL="2" V="7">
                    <C O="46" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="48" T="[0]" TL="2" V="3">$calling-device</P>
                    </C O="53" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="53" T="[APPLICATION 1]" L="9">
                <C O="53" T="[APPLICATION 2]" TL="2" V="7">
                    <C O="55" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="57" T="[0]" TL="2" V="3">$called-device</P>
                    </C O="62" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="62" T="[APPLICATION 2]" L="9">
                <C O="62" T="[APPLICATION 4]" TL="2" V="2">
                    <P O="64" T="[7]" TL="2" V="0"></P>
                </C O="66" T="[APPLICATION 4]" L="4">
                <P O="66" T="[APPLICATION 14]" TL="2" V="1">$connection-info</P>
                <P O="69" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">$cause</P>
                <C O="72" T="[APPLICATION 30]" TL="2" V="18">
                    <C O="74" T="[0]" TL="2" V="16">
                        <P O="76" T="[UNIVERSAL 24]" TL="2" V="14" A="GeneralizedTime">$timestamp</P>
                    </C O="92" T="[0]" L="18">
                </C O="92" T="[APPLICATION 30]" L="20">
            </C O="92" T="[4]" L="76">
        </C O="92" T="[0]" L="78">
    </C O="92" T="[UNIVERSAL 16]" A="SEQUENCE" L="84">
</C O="92" T="[1]" L="92">
END
return $heredoc;
}

sub CSTA_MonitorStartResponse {
$heredoc = <<'END';
<C O="0" T="[2]" TL="2" V="14">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">&#x01;</P>
    <C O="5" T="[UNIVERSAL 16]" TL="2" V="9" A="SEQUENCE">
        <P O="7" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">&#x47;</P>
        <C O="10" T="[UNIVERSAL 16]" TL="2" V="4" A="SEQUENCE">
            <P O="12" T="[APPLICATION 21]" TL="2" V="$cross-ref-identifier_length">$cross-ref-identifier</P>
        </C O="16" T="[UNIVERSAL 16]" A="SEQUENCE" L="6">
    </C O="16" T="[UNIVERSAL 16]" A="SEQUENCE" L="11">
</C O="16" T="[2]" L="16">
END
return $heredoc;
}

sub CSTA_MonitorStart {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="53">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="$invoke-id_length" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="$operation-value_length" A="INTEGER">$operation-value</P>
    <C O="8" T="[UNIVERSAL 16]" TL="2" V="45" A="SEQUENCE">
        <C O="10" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
            <P O="12" T="[0]" TL="2" V="$dialing-number_length">$dialing-number</P>
        </C O="17" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
        <C O="17" T="[0]" TL="2" V="36">
            <P O="19" T="[0]" TL="2" V="4">$call-control</P>
            <P O="25" T="[6]" TL="2" V="2">$call-associated</P>
            <P O="29" T="[7]" TL="2" V="2">$media-attachment</P>
            <P O="33" T="[8]" TL="2" V="3">$physical-device-feature</P>
            <P O="38" T="[9]" TL="2" V="3">$logical-device-feature</P>
            <P O="43" T="[3]" TL="2" V="2">$maintainance</P>
            <P O="47" T="[5]" TL="2" V="2">$voice-unit</P>
            <P O="51" T="[4]" TL="2" V="2">$private</P>
        </C O="55" T="[0]" L="38">
    </C O="55" T="[UNIVERSAL 16]" A="SEQUENCE" L="47">
</C O="55" T="[1]" L="55">
END
return $heredoc;
}

sub CSTA_MonitorStopResponse {
$heredoc = <<'END';
<C O="0" T="[2]" TL="2" V="10">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <C O="5" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
        <P O="7" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">&#x49;</P>
        <P O="10" T="[UNIVERSAL 5]" TL="2" V="0" A="NULL"></P>
    </C O="12" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
</C O="12" T="[2]" L="12">
END
return $heredoc;
}

sub CSTA_MakeCallResponse {
$heredoc = <<'END';
<C O="0" T="[2]" TL="2" V="27">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <C O="5" T="[UNIVERSAL 16]" TL="2" V="22" A="SEQUENCE">
        <P O="7" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$operation-value</P>
        <C O="10" T="[UNIVERSAL 16]" TL="2" V="17" A="SEQUENCE">
            <C O="12" T="[APPLICATION 11]" TL="2" V="15">
                <C O="14" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                    <P O="16" T="[0]" TL="2" V="2">$call-id</P>
                    <C O="20" T="[1]" TL="2" V="7">
                        <C O="22" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                            <P O="24" T="[0]" TL="2" V="3">$dialing-number</P>
                        </C O="29" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                    </C O="29" T="[1]" L="9">
                </C O="29" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
            </C O="29" T="[APPLICATION 11]" L="17">
        </C O="29" T="[UNIVERSAL 16]" A="SEQUENCE" L="19">
    </C O="29" T="[UNIVERSAL 16]" A="SEQUENCE" L="24">
</C O="29" T="[2]" L="29">
END
return $heredoc;
}

sub CSTA_MakeCall {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="22">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">&#x0a;</P>
    <C O="8" T="[UNIVERSAL 16]" TL="2" V="14" A="SEQUENCE">
        <C O="10" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
            <P O="12" T="[0]" TL="2" V="3">$calling-device</P>
        </C O="17" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
        <C O="17" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
            <P O="19" T="[0]" TL="2" V="3">$called-device</P>
        </C O="24" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
    </C O="24" T="[UNIVERSAL 16]" A="SEQUENCE" L="16">
</C O="24" T="[1]" L="24">
END
return $heredoc;
}

sub CSTA_SetDisplay {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="23">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="2" A="INTEGER">&#x01;&#x12;</P>
    <C O="9" T="[UNIVERSAL 16]" TL="2" V="14" A="SEQUENCE">
        <C O="11" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
            <P O="13" T="[0]" TL="2" V="3">$device</P>
        </C O="18" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
        <P O="18" T="[UNIVERSAL 22]" TL="2" V="5" A="IA5String">$text</P>
    </C O="25" T="[UNIVERSAL 16]" A="SEQUENCE" L="16">
</C O="25" T="[1]" L="25">
END
return $heredoc;
}

sub CSTA_SetDisplayResponse {
	# it is the general ROSE RORS packet, no need too duplicate it
	return CSTA_SystemStatusResponse();
}


sub CSTA_MonitorStop {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="12">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">&#x49;</P>
    <C O="8" T="[UNIVERSAL 16]" TL="2" V="4" A="SEQUENCE">
        <P O="10" T="[APPLICATION 21]" TL="2" V="2">$cross-ref-identifier</P>
    </C O="14" T="[UNIVERSAL 16]" A="SEQUENCE" L="6">
</C O="14" T="[1]" L="14">
END
return $heredoc;
}

sub CSTA_SystemStatusResponse {
$heredoc = <<'END';
<C O="0" T="[2]" TL="2" V="11">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <C O="5" T="[UNIVERSAL 16]" TL="2" V="6" A="SEQUENCE">
        <P O="7" T="[UNIVERSAL 2]" TL="2" V="2" A="INTEGER">$operation-value</P>
        <P O="11" T="[UNIVERSAL 5]" TL="2" V="0" A="NULL"></P>
    </C O="13" T="[UNIVERSAL 16]" A="SEQUENCE" L="8">
</C O="13" T="[2]" L="13">
END
return $heredoc;
}

sub CSTA_RosePacketDecode {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="68">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$operation-value</P>
</C O="70" T="[1]" L="70">
END
return $heredoc;
}

sub CSTA_EventReport_Established {
$heredoc = <<'END';
<C O="0" T="[1]" TL="2" V="90">
    <P O="2" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$invoke-id</P>
    <P O="5" T="[UNIVERSAL 2]" TL="2" V="1" A="INTEGER">$operation-value</P>
    <C O="8" T="[UNIVERSAL 16]" TL="2" V="82" A="SEQUENCE">
        <P O="10" T="[APPLICATION 21]" TL="2" V="2">$cross-ref-identifier</P>
        <C O="14" T="[0]" TL="2" V="76">
            <C O="16" T="[7]" TL="2" V="74">
                <C O="18" T="[APPLICATION 11]" TL="2" V="15">
                    <C O="20" T="[UNIVERSAL 16]" TL="2" V="13" A="SEQUENCE">
                        <P O="22" T="[0]" TL="2" V="2">$call-id</P>
                        <C O="26" T="[1]" TL="2" V="7">
                            <C O="28" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                                <P O="30" T="[0]" TL="2" V="3">$dialing-number</P>
                            </C O="35" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                        </C O="35" T="[1]" L="9">
                    </C O="35" T="[UNIVERSAL 16]" A="SEQUENCE" L="15">
                </C O="35" T="[APPLICATION 11]" L="17">
                <C O="35" T="[APPLICATION 3]" TL="2" V="7">
                    <C O="37" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="39" T="[0]" TL="2" V="3">$answering-device</P>
                    </C O="44" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="44" T="[APPLICATION 3]" L="9">
                <C O="44" T="[APPLICATION 1]" TL="2" V="7">
                    <C O="46" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="48" T="[0]" TL="2" V="3">$calling-device</P>
                    </C O="53" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="53" T="[APPLICATION 1]" L="9">
                <C O="53" T="[APPLICATION 2]" TL="2" V="7">
                    <C O="55" T="[UNIVERSAL 16]" TL="2" V="5" A="SEQUENCE">
                        <P O="57" T="[0]" TL="2" V="3">$called-device</P>
                    </C O="62" T="[UNIVERSAL 16]" A="SEQUENCE" L="7">
                </C O="62" T="[APPLICATION 2]" L="9">
                <C O="62" T="[APPLICATION 4]" TL="2" V="2">
                    <P O="64" T="[7]" TL="2" V="0"></P>
                </C O="66" T="[APPLICATION 4]" L="4">
                <P O="66" T="[APPLICATION 14]" TL="2" V="1">$connection-info</P>
                <P O="69" T="[UNIVERSAL 10]" TL="2" V="1" A="ENUMERATED">$cause</P>
                <C O="72" T="[APPLICATION 30]" TL="2" V="18">
                    <C O="74" T="[0]" TL="2" V="16">
                        <P O="76" T="[UNIVERSAL 24]" TL="2" V="14" A="GeneralizedTime">$timestamp</P>
                    </C O="92" T="[0]" L="18">
                </C O="92" T="[APPLICATION 30]" L="20">
            </C O="92" T="[7]" L="76">
        </C O="92" T="[0]" L="78">
    </C O="92" T="[UNIVERSAL 16]" A="SEQUENCE" L="84">
</C O="92" T="[1]" L="92">
END
return $heredoc;
}



1;
