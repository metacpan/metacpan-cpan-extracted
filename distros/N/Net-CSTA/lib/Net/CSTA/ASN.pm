
package Net::CSTA::ASN;
use Convert::ASN1;
use vars qw($asn);

my $asn = Convert::ASN1->new;

sub import {
  my $pkg    = shift;
  my $caller = caller;

  foreach my $macro (@_) {
    my $obj = $asn->find($macro)
      or require Carp and Carp::croak("Unknown macro '$macro'");

    *{"$caller\::$macro"} = \$obj;
  }
}

sub asn
{
	$asn;
}

$asn->prepare(<<EOASN) or die $asn->error;

-- Dedalus Engenharia S/C Ltda         Convenio GMK/FDTE
-- -------------------------------------------------------------------------
-- Arquivo   : csta.asn
-- Descricao : Especificacao das PDUS do protocolo CSTA para ser compilada
--             pelo programa snacc v1.1
--
-- -------------------------------------------------------------------------
-- Historico :
-- 02/08/95...PMS...Versao Inicial
-- 05/02/97...PMS...Revisao para Application Link 2.0
-- 25/02/97...FES...Introducao de Snapshot e SystemStatus.
-- 01/10/97...PMS...EventCause completado
-- 03/11/98...PMS...Inclusao de dados privados em eventos
-- *************************************************************************

-- =====================================================
-- PDUs do ROSE, que sao utilizadas pelo protocolo CSTA
-- =====================================================
CSTAapdu ::= CHOICE {
        svcRequest      ROIVapdu,
        svcResult       RORSapdu,
        svcError        ROERapdu,
        svcReject       RORJapdu
}

-- =====================================================
-- Invoke PDU
-- =====================================================

ROIVapdu ::=  [1] IMPLICIT SEQUENCE {
	invokeID	  INTEGER,  -- no. de sequencia
	serviceID	  INTEGER,  -- no. da operacao a ser realizada
	serviceArgs	  ANY DEFINED BY serviceID -- Uma das estruturas abaixo
}


-- Codigos dos servicos CSTA. Isto deve gerar um enum no C para ser utilizado
-- como o valor do campo serviceID em ROIVapdu
CSTAServices ::= ENUMERATED {
	alternateCallSID	(1),
	answerCallSID		(2),
	callCompletionSID	(3), -- Novo
	--clearCallSID		(4), Nao suportado
	clearConnectionSID	(5),
	conferenceCallSID	(6),
	consultationCallSID	(7),
	divertCallSID		(8),
	holdCallSID		(9), -- Novo
	makeCallSID		(10),
	makePredictiveCallSID	(11), -- Novo
	queryDeviceSID		(12),
	reconnectCallSID	(13), -- Novo
	retrieveCallSID		(14),
	setFeatureSID		(15),
	transferCallSID		(16),
	eventReportSID		(21),
	systemStatusSID		(52), -- Novo
	monitorStartSID		(71),
	changeMonitorFilterSID	(72), -- Novo
	monitorStopSID		(73),
	snapshotDeviceSID	(74) -- Novo
}

-- Estruturas que podem ocorrer no ANY do ROIVapdu. O codigo gerado
-- deve decodificar o tipo sem maiores problemas

-- Alternate Call
AlternateCallArgs ::= ConnectionDetails


-- Answer Call
AnswerCallArgs	  ::= ConnectionID

-- Call Completion
CallCompletionArgs ::= FeatureInfo

-- Clear Connection
ClearConnectionArgs ::= ConnectionID

-- Conference Call
ConferenceCallArgs  ::= ConnectionDetails

-- Consultation Call
ConsultationCallArgs ::= SEQUENCE {
	existingCall	ConnectionID,
	calledDirectoryNumber	CalledDeviceID 
}

-- Divert Call
DivertCallArgs ::= DivertInfo

-- Hold Call
HoldCallArgs ::= SEQUENCE {
	callToBeHeld	ConnectionID,
	connectionReservation ReserveConnection
}

-- Make Call
MakeCallArgs ::= SEQUENCE {
	callingDevice	DeviceID,
	calledDirectoryNumber	CalledDeviceID
}

-- Query device
QueryDeviceArgs ::= SEQUENCE {
	device		DeviceID,
	feature		QueryDeviceFeature
}

-- Reconnect Call
ReconnectCallArgs  ::= ConnectionDetails

-- Retrieve Call
RetrieveCallArgs ::= ConnectionID

-- Set feature
SetFeatureArgs ::= SEQUENCE {
	device		DeviceID,
	feature		SetDeviceFeature
}

-- Transfer call
TransferCallArgs ::= ConnectionDetails

-- Monitor Start
MonitorStartArgs ::= SEQUENCE {
	monitorObject	MonitorObject,
	monitorFilter	MonitorFilter	OPTIONAL,
	monitorType	MonitorType	OPTIONAL
}

-- Monitor Stop
MonitorStopArgs ::= MonitorCrossRefID

-- Change Monitor Filter
ChangeMonitorFilterArgs ::= SEQUENCE {
	monitorCrossRefID	MonitorCrossRefID,
	filterlist		MonitorFilter
}

-- SnapshotDevice
SnapshotDeviceArgs ::= DeviceID  
		  
-- System Status (pode ser enviada ou recebida)
SystemStatusArgs ::=  SystemStatus


-- =============================================================
-- Result PDU generica
-- =============================================================

RORSapdu ::= [2] IMPLICIT SEQUENCE {
	invokeID	  INTEGER,     -- no. de sequencia
	result            SEQUENCE {
		serviceID	  INTEGER,
		serviceResult	  ANY DEFINED BY serviceID OPTIONAL
	}
}

-- PMS 22/04/97 : O Any acima era DEFINED pelo invokeID. No caso
-- do Application Link, os resultados aparecem cercados por
-- uma SEQUENCE, impedindo o seu uso. A solucao foi usar o
-- DEFINED BY serviceID. De resto, vale o comentario abaixo...

-- Alterar o codigo resultante !!! O invokeID nao identifica
-- diretamente qual o tipo de dados em serviceResult, o qual
-- deve ser comparado com a PDU de invoke com o mesmo ID


-- Estruturas que retornam em serviceResult

ConferenceCallRS ::= SEQUENCE {
		conferenceCall	ConnectionID,
		connection	ConnectionList OPTIONAL
}


ConsultationCallRS ::= ConnectionID

MakeCallRS ::= ConsultationCallRS
	
QueryDeviceRS ::=  QueryDeviceInformation



TransferCallRS ::= SEQUENCE {
			transferredCall	ConnectionID OPTIONAL,
			connections	ConnectionList OPTIONAL
}


MonitorStartRS ::=  SEQUENCE {
			crossRefIdentifier	MonitorCrossRefID,
			monitorFilter		MonitorFilter OPTIONAL
}

MonitorStopRS ::= NULL

ChangeMonitorFilterRS ::= [0] IMPLICIT MonitorFilter

SnapshotDeviceRS ::= SnapshotDeviceData

DivertCallRS ::= CHOICE { noData NULL }

-- =====================================================================
-- Outras PDUs do ROSE que podem ocorrer em um dialogo CSTA
-- =====================================================================

-- Error PDU (Erro detectado pelo executor da operacao)
ROERapdu ::= [3] IMPLICIT SEQUENCE {
	invokeID	 INTEGER,      -- no. de sequencia
	unknown		 INTEGER,      -- @@@ descobrir o que e' 
	typeOfError      UniversalCauseItem -- Tipo do erro
}

-- Causas de erro

UniversalCauseItem ::= CHOICE {
	operationErrors		[1] IMPLICIT Operations,
	stateErrors		[2] IMPLICIT StateIncompatibility,
	systemResourceErrors	[3] IMPLICIT SystemResourceAvailability,
	subscribedResourceErrors [4] IMPLICIT SubscribedResourceAvailability,
	performanceErrors	[5] IMPLICIT PerformanceManagement,
	unspecifiedErrors	[6] IMPLICIT NULL
}

Operations ::= ENUMERATED {
	generic				(1),
	requestIncompatibleWithObject	(2),
	valueOutOfRange			(3),
	objectNotKnown			(4),
	invalidCallingDevice		(5),
	invalidCalledDevice		(6),
	invalidForwardingDevice		(7),
	privilegeViolationOnSpecifiedDevice (8),
	privilegeViolationOnCalledDevice (9),
	privilegeViolationOnCallingDevice (10),
	invalidCallIdentifier		  (11),
	invalidDeviceIdentifier		  (12),
	invalidConnectionIdentifier	  (13),
	invalidDestination		  (14),
	invalidFeature			  (15),
	invalidAllocationState		  (16),
	invalidCrossReferenceID		  (17),
	invalidObjectType		  (18),
	securityViolation		  (19)
}

StateIncompatibility ::= ENUMERATED {
	generic			(1),
	incorrectObjectState	(2),
	invalidConnectionID	(3),
	noActiveCall		(4),
	noHeldCall		(5),
	noCallToClear		(6),
	noConnectionToClear	(7),
	noCallToAnswer		(8),
	noCallToComplete	(9)
}

SystemResourceAvailability ::= ENUMERATED {
	generic			(1),
	serviceBusy		(2),
	resourceBusy		(3),
	resourceOutOfService	(4),
	networkBusy		(5),
	networkOutOfService	(6),
	overallMonitorLimitExceeded (7),
	conferenceMemberLimitExceeded (8)
}

SubscribedResourceAvailability ::= ENUMERATED {
	generic			(1),
	objectMonitorLimitExceeded (2),
	externalTrunkLimitExceeded (3),
	outstandingRequestLimitExceeded (4)
}

PerformanceManagement ::= ENUMERATED {
	generic		(1),
	performanceLimitExceeded (2)
}

ProblemType ::= CHOICE {
                general [0] IMPLICIT GeneralProblem,
                invoke  [1] IMPLICIT InvokeProblem,
                result  [2] IMPLICIT ReturnResultProblem,
                error   [3] IMPLICIT ReturnErrorProblem
}

-- Reject PDU (Erro detectado pelo ROSE)
RORJapdu ::= [4] IMPLICIT SEQUENCE {
	invokeID INTEGER,
	typeOfProblem  ProblemType
}

-- Causas de rejeicao

GeneralProblem ::= ENUMERATED {
	unrecognizedAPDU	(0),
	mistypedAPDU		(1),
	badlyStructuredAPDU	(2)
}

InvokeProblem ::= ENUMERATED {
	duplicateInvocation	(0),
	unrecognizedOperation	(1),
	mistypedArgument	(2),
	resourceLimitation	(3),
	initiatorReleasing	(4),
	unrecognizedLinkedID	(5),	-- Nao ocorre no CSTA
	linkedResponseUnexpected (6),   --  "    "    "    "
	unexepectedChildOperation (7)   --  "    "    "    " 
}

ReturnResultProblem ::= ENUMERATED {
	unrecognizedInvocation		(0),
	resultResponseUnexpected	(1),
	mistypedResult			(2)
}

ReturnErrorProblem ::= ENUMERATED {
	unrecognizedInvocation		(0),
	errorResponseUnexpected		(1),
	unrecognizedError		(2),
	unexpectedError			(3),
	mistypedParameter		(4)
}


-- ============================================
-- Argumentos das primitivas CSTA
-- ============================================




-- ======================================================
--  Eventos do CSTA
-- ======================================================


-- Evento generico
EventReport ::= SEQUENCE {
	crossRefIdentifier	MonitorCrossRefID,
	eventType		[0] IMPLICIT INTEGER,
	eventInfo		ANY DEFINED BY eventType
}


-- Codigo dos eventos
--CSTAEvents ::= ENUMERATED {
--	callCleared		(1), - Nao suportado
--	conferenced		(2),
--	connectionCleared	(3),
--	delivered		(4),
--	diverted		(5), - Suportado apenas em filas
--	established		(6),
--	failed			(7),
--	held			(8),
--	networkReached		(9),
--	originated		(10),
--	queued			(11), - Suportado em filas
--	retrieved		(12),
--	serviceInitiated	(13),
--	transferred		(14),
--	doNotDisturb		(102),
--	forwarding		(103),
--	loggedOn		(201),
--	loggedOff		(202),
--	notReady		(203),
--	ready			(204),
--	backInService		(301),
--	outOfService		(302)
--}


-- Dados dos eventos que vem no eventInfo de EventReport

Conferenced ::= SEQUENCE {
			primaryOldCall		ConnectionID,
			secondaryOldCall	ConnectionID OPTIONAL,
			confController		SubjectDeviceID,
			addedParty		SubjectDeviceID,
			conferenceConnections	ConnectionList OPTIONAL,
			localConnectionInfo	LocalConnectionState,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL
		}

ConnectionCleared ::= SEQUENCE {
			droppedConnection	ConnectionID,
			releasingDevice		SubjectDeviceID,
			localConnectionInfo	LocalConnectionState,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
		}

Delivered ::= SEQUENCE {
			connectionID		ConnectionID,
			alertingDevice		SubjectDeviceID,
			callingDevice		CallingDeviceID,
			calledDevice		CalledDeviceID,
			lastRedirectionDevice	RedirectionDeviceID,
			localConnectionInfo	LocalConnectionState OPTIONAL,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL
}

Diverted ::= SEQUENCE {
	connection		ConnectionID	OPTIONAL,
	divertingDevice		SubjectDeviceID,
	newDestination		CalledDeviceID,
	localConnectionInfo	LocalConnectionState OPTIONAL,
	cause			EventCause OPTIONAL,
	private			PrivateData OPTIONAL			
}

Established ::= SEQUENCE {
			establishedConn		ConnectionID,
			answeringDevice		SubjectDeviceID,
			callingDevice		CallingDeviceID,
			calledDevice		CalledDeviceID,
			lastRedirectionDevice	RedirectionDeviceID,
			localConnectionInfo	LocalConnectionState OPTIONAL,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
		}



Failed ::=  SEQUENCE {
			failedConnection	ConnectionID,
			failedDevice		SubjectDeviceID,
			calledNumber		CalledDeviceID,
			localConnectionInfo	LocalConnectionState OPTIONAL,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
		}


Held ::= SEQUENCE {
			heldConnection		ConnectionID,
			holdingDevice		SubjectDeviceID,
			localConnectionInfo	LocalConnectionState OPTIONAL,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
			
		}



NetworkReached ::= SEQUENCE {
			connection		ConnectionID,
			trunkUsed		SubjectDeviceID,
			calledDevice		CalledDeviceID,
			localConnectionInfo	LocalConnectionState OPTIONAL,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
	}

Originated ::=  SEQUENCE {
	originatedConnection		ConnectionID,
	callingDevice			SubjectDeviceID,
	calledDevice			CalledDeviceID,
	localConnectionInfo		LocalConnectionState OPTIONAL,
	cause				EventCause OPTIONAL,			
	private			PrivateData OPTIONAL			
}

Queued ::=  SEQUENCE {
	queuedConnection		ConnectionID,
	queue				SubjectDeviceID,
	callingDevice			CallingDeviceID,
	calledDevice			CalledDeviceID,
	lastRedirectionDevice		RedirectionDeviceID,
	numberedQueued			NoOfCallsInQueue OPTIONAL,
	localConnectionInfo		LocalConnectionState OPTIONAL,
	cause				EventCause OPTIONAL,
	private			PrivateData OPTIONAL			
}
	


Retrieved ::=  SEQUENCE {
			retrievedConnection	ConnectionID,
			retrievingDevice	SubjectDeviceID,
			localConnectionInfo	LocalConnectionState,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
		}


ServiceInitiated ::= SEQUENCE {
			initiatedConnection	ConnectionID,
			localConnectionInfo	LocalConnectionState,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
		}



Transferred ::= SEQUENCE {
			primaryOldCall		ConnectionID,
			secondaryOldCall	ConnectionID OPTIONAL,
			transferringDevice	SubjectDeviceID,
			transferredDevice	SubjectDeviceID,
			transferredConnections	ConnectionList OPTIONAL,
			localConnectionInfo	LocalConnectionState,
			cause			EventCause OPTIONAL,
			private			PrivateData OPTIONAL			
	}
	

DoNotDisturb ::= SEQUENCE {
	device		SubjectDeviceID,
	doNotDisturbOn	BOOLEAN
}

Forwarding  ::= SEQUENCE {
	device			SubjectDeviceID,
	forwardingInformation	ForwardParameter
}

LoggedOn  ::= SEQUENCE {
	agentDevice		SubjectDeviceID,
	agentID			[10] IMPLICIT AgentID OPTIONAL,
	agentGroup		AgentGroup OPTIONAL,
	password		[11] IMPLICIT AgentPassword OPTIONAL	
}

LoggedOff  ::= SEQUENCE {
	agentDevice		SubjectDeviceID,
	agentID			[10] IMPLICIT AgentID OPTIONAL,
	agentGroup		AgentGroup OPTIONAL
}

NotReady  ::= SEQUENCE {
	agentDevice		SubjectDeviceID,
	agentID			[10] IMPLICIT AgentID OPTIONAL
}

Ready  ::= SEQUENCE {
	agentDevice		SubjectDeviceID,
	agentID			[10] IMPLICIT AgentID OPTIONAL
}

BackInService  ::= SEQUENCE {
	device		DeviceID,
	cause		EventCause OPTIONAL
}

OutOfService  ::= SEQUENCE {
	device		DeviceID,
	cause		EventCause OPTIONAL
}

--======================================================
-- Definicao um tanto generica para dados privados
--======================================================
PrivateData ::= [APPLICATION 29] IMPLICIT SEQUENCE {
	manufacturer	OBJECT IDENTIFIER,
	data		ANY
}


-- ======================================================
--  Tipos de dados do CSTA
-- ======================================================

-- Objetos do CSTA genericos

CSTAObject ::= DeviceID


-- Dispositivos CSTA (O telefone...)

DeviceInfo ::= SEQUENCE {
	deviceId	DeviceID OPTIONAL,
	deviceType	DeviceType OPTIONAL,
	deviceClass	DeviceClass OPTIONAL
}

DeviceID ::= CHOICE {
	dialingNumber [0] IMPLICIT NumberDigits,
	deviceNumber  [1] IMPLICIT DeviceNumber
}


DeviceNumber ::= INTEGER

NumberDigits ::= IA5String

-- "importado" de useful.asn1
IA5String        ::= [UNIVERSAL 22] IMPLICIT OCTET STRING 

DeviceType ::= ENUMERATED {
	station	(0)
}

DeviceClass ::= BIT STRING 

OtherPlan ::= OCTET STRING

ExtendedDeviceID ::= CHOICE {
	deviceID	DeviceID,
	implicitPublic	[2] IMPLICIT NumberDigits,
	explicitPublic	[3] PublicTON,
	implicitPrivate	[4] IMPLICIT NumberDigits,
	explicitPrivate	[5] PrivateTON,
	other		[6] IMPLICIT OtherPlan }
	

CallingDeviceID ::= [APPLICATION 1] CHOICE {
	deviceID	ExtendedDeviceID,
	notKnown	[7] IMPLICIT NULL,
	notRequired	[8] IMPLICIT NULL
}


CalledDeviceID ::= [APPLICATION 2] CHOICE {
	deviceID	 ExtendedDeviceID,
	notKnown	[7] IMPLICIT NULL,
	notRequired	[8] IMPLICIT NULL
}
		

SubjectDeviceID ::= [APPLICATION 3] CHOICE {
	deviceID	 ExtendedDeviceID,
	notKnown	[7] IMPLICIT NULL,
	notRequired	[8] IMPLICIT NULL
}

RedirectionDeviceID ::= [APPLICATION 4] CHOICE {
	deviceID	 ExtendedDeviceID,
	notKnown	[7] IMPLICIT NULL,
	notRequired	[8] IMPLICIT NULL
}

PublicTON ::= CHOICE {
	unknown		[0]	IMPLICIT IA5String,
	international	[1]	IMPLICIT IA5String,
	national	[2]	IMPLICIT IA5String,
	networkspecific	[3]	IMPLICIT IA5String,
	subscriber	[4]	IMPLICIT IA5String,
	abreviated	[5]	IMPLICIT IA5String
}

PrivateTON ::= CHOICE {
	unknown			[0]	IMPLICIT IA5String,
	level3RegionalNumber	[1]	IMPLICIT IA5String,
	level2RegionalNumber	[2]	IMPLICIT IA5String,
	level1RegionalNumber	[3]	IMPLICIT IA5String,
	pTNSpecificNumber	[4]	IMPLICIT IA5String,
	localNumber		[5]	IMPLICIT IA5String,
	abbreviated		[6]	IMPLICIT IA5String
}

-- Conexoes do DAC

ConnectionID ::= [APPLICATION 11] IMPLICIT SEQUENCE {
	call	[2] IMPLICIT OCTET STRING OPTIONAL,
	device	[0] IMPLICIT NumberDigits OPTIONAL
}

ConnectionList ::= [APPLICATION 12] IMPLICIT SEQUENCE OF ConnectionID

LocalConnectionState ::= [APPLICATION 14] IMPLICIT ENUMERATED {
	nullConnection	(0),
	initiate	(1),
	alerting	(2),
	connect		(3),
	hold		(4),
	fail		(6)
}

-- Estruturas auxiliares usadas na definicao
-- de argumentos

ConnectionDetails ::= CHOICE {
	heldCall	[0] IMPLICIT ConnectionID,
	activeCall	[1] IMPLICIT ConnectionID,
	bothCalls	[2] IMPLICIT SEQUENCE {
		heldCall	ConnectionID,
		activeCall	ConnectionID
	}
}

DivertInfo ::= [0] IMPLICIT SEQUENCE {
	callToBeDiverted	ConnectionID,
	newDestination		CalledDeviceID
}

-- Info retorna
-- Estruturas para a SetFeature
SetDeviceFeature ::= CHOICE {
	msgWaitingOn	[0] IMPLICIT BOOLEAN,
	doNotDisturb	[1] IMPLICIT BOOLEAN,
	forward		[2] IMPLICIT ForwardParameter,
	requestedAgentState [3] AgentParameter
}

QueryDeviceFeature ::= ENUMERATED {
	msgWaintingOn		(0),
	doNotDisturb		(1),
	forward			(2),
	deviceInfo		(4),
	agentState		(5)
}

QueryDeviceInformation ::= CHOICE {
	msgWaitingOn	[0] IMPLICIT BOOLEAN,
	doNotDisturb	[1] IMPLICIT BOOLEAN,
	forward		[2] IMPLICIT ListForwardParameter,
	deviceInfo	[4] IMPLICIT DeviceInfo,
	agentState	[5] IMPLICIT AgentState
}

FeatureInfo ::= CHOICE {
	campon		[0] IMPLICIT	ConnectionID,
	callback	[1] IMPLICIT	ConnectionID,
	intrude		[2] IMPLICIT	ConnectionID
}

ReserveConnection ::= BOOLEAN

NoOfCallsInQueue ::= INTEGER

ForwardParameter ::= SEQUENCE {
	forwardingType	ForwardingType,
	forwardDN	NumberDigits OPTIONAL
}

ListForwardParameter ::= SEQUENCE {
	forwardingType	ForwardingType,
	forwardDN	NumberDigits
}

ForwardingType ::= ENUMERATED {
	forwardAlwaysOn		(0),
	forwardAlwaysOff	(1),
	forwardBusyOn		(2),
	forwardBusyOff		(3),
	forwardNoAnsOn		(4),
	forwardNoAnsOff		(5) 
}		

AgentID ::= OCTET STRING

AgentGroup ::= DeviceID

AgentPassword ::= OCTET STRING

LoggedOnInfo ::= SEQUENCE {
	agentGroup	AgentGroup OPTIONAL
}

LoggedOffInfo ::= SEQUENCE {
	agentGroup	AgentGroup OPTIONAL
}

AgentParameter ::= CHOICE {
	logOn		[0] IMPLICIT LoggedOnInfo,
	logOff		[1] IMPLICIT LoggedOffInfo,
	notReady	[2] IMPLICIT NULL,
	readyInfo	[3] IMPLICIT NULL,
	workNotReady	[4] IMPLICIT NULL,
	workReady	[5] IMPLICIT NULL
}

AgentState ::= ENUMERATED {
	logOut		(0),
	notReady	(1),
	ready		(2),
	workNotReady	(3),
	workReady	(4)
}


-- Tipos utilizados nos eventos de monitoracao

MonitorObject ::= CSTAObject

MonitorCrossRefID ::= [APPLICATION 21] IMPLICIT OCTET STRING

MonitorFilter ::= SEQUENCE {
	call		[0] IMPLICIT CallFilter,
	feature		[1] IMPLICIT FeatureFilter,
	agent		[2] IMPLICIT AgentFilter,
	maintenance	[3] IMPLICIT MaintenanceFilter,
	private		[4] IMPLICIT BOOLEAN
}


CallFilter ::= BIT STRING

FeatureFilter ::= BIT STRING

AgentFilter ::= BIT STRING

MaintenanceFilter ::= BIT STRING

MonitorType ::= ENUMERATED {
	call	(0),
	device	(1)
}

-- Tipos para o Snapshot

SnapshotDeviceData ::= [APPLICATION 22] IMPLICIT SEQUENCE OF
	SnapshotDeviceResponseInfo
	
SnapshotDeviceResponseInfo ::= SEQUENCE {
	deviceOnCall		SubjectDeviceID,
	callIdentifier		ConnectionID,
	localConnectionState	LocalConnectionState OPTIONAL
}


EventCause ::= ENUMERATED {
	activeMonitor		(1),
	alternate		(2),
	busy			(3),
	callback		(4),
	callCancelled		(5),
	callForwardAlways 	(6),
	callForwardBusy	  	(7),
	callForwardNoAnswer 	(8),
	callForward		(9),
	callNotAnswered 	(10),
	callPickup		(11),
	campOn			(12),
	destNotObtainable 	(13),
	doNotDisturb		(14),
	incompatibleDestination	(15),
	invalidAccountCode	(16),
	lockout			(18),
	maintanance		(19),
	networkCongestion	(20),
	networkNotObtainable	(21),
	newCall			(22),
	noAvailableAgents	(23),
	override		(24),
	park			(25),
	cstaOverflow		(26), -- Mudado de overflow para nao colidir 
                                      -- com <math.h> no fonte gerado
	recall			(27),
	redirected		(28),
	reorderTone		(29),
	resourcesNotAvailable	(30),
	silentMonitor		(31),
	transfer		(32),
	trunkBusy		(33),
	voiceUnitInitiator	(34)
}

-- Tipos para a transacao de status operacional

SystemStatus ::= ENUMERATED {
	initializing		(0),
	enabled			(1),
	normal			(2),
	messagesLost		(3),
	disabled		(4),
	overloadImminent	(5),
	overloadReached		(6),
	overloadRelieved	(7)
}


EOASN

my %serviceArgs = (
	#1 => 'alternateCall',	
	#2 => 'answerCall',
	#3 => 'callCompletion'
	#4 => clearCall,
	#5 => 'clearConnection',
	6 => 'ConferenceCallArgs',
	7 => 'ConsultationCallArgs',
	8 => 'DivertCallArgs',
	#9 => 'holdCall',
	10 => 'MakeCallArgs',
	#11 => 'makePredictiveCall',
	12 => 'QueryDeviceArgs',
	13 => 'ReconnectCallArgs',
	14 => 'RetrieveCallArgs',
	15 => 'SetFeatureArgs',
	16 => 'TransferCallArgs',
	21 => 'EventReport',
	52 => 'SystemStatusArgs',
	71 => 'MonitorStartArgs',
	72 => 'ChangeMonitorFilterArgs',
	73 => 'MonitorStopArgs',
	74 => 'SnapshotDeviceArgs'
);

foreach (keys %serviceArgs) {
	$asn->registertype('serviceArgs',$_,$asn->find($serviceArgs{$_}));
}

my %serviceResults = (
	#1 => 'alternateCall',	
	#2 => 'answerCall',
	#3 => 'callCompletion'
	#4 => clearCall,
	#5 => 'clearConnection',
	6 => 'ConferenceCallRS',
	7 => 'ConsultationCallRS',
	8 => 'DivertCallRS',
	#9 => 'holdCall',
	10 => 'MakeCallRS',
	#11 => 'makePredictiveCall',
	12 => 'QueryDeviceRS',
	13 => 'ReconnectCallRS',
	14 => 'RetrieveCallRS',
	15 => 'SetFeatureRS',
	16 => 'TransferCallRS',
	21 => 'EventReport',
	52 => 'SystemStatusArgs',
	71 => 'MonitorStartRS',
	72 => 'ChangeMonitorFilterRS',
	73 => 'MonitorStopRS',
	74 => 'SnapshotDeviceRS'
);

foreach (keys %serviceResults) {
	$asn->registertype('serviceResult',$_,$asn->find($serviceResults{$_}));
}

my %eventInfos = (
	3 => 'ConnectionCleared',
	4 => 'Delivered',
	5 => 'Diverted',
	6 => 'Established',
	7 => 'Failed',
	8 => 'Held',
	9 => 'NetworkReached',
	10 => 'Originated',
	11 => 'Queued',
	12 => 'Retrieved',
	13 => 'ServiceInitiated',
	14 => 'Transferred',
	102 => 'DoNotDisturb',
	103 => 'Forwarding',
	201 => 'LoggedOn',
	202 => 'LoggedOff',
	203 => 'NotReady',
	204 => 'Ready',
	301 => 'BackInService',
	302 => 'OutOfService'
);

foreach (keys %eventInfos) {
	$asn->registertype('eventInfo',$_,$asn->find($eventInfos{$_}));
}

1;
