use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.057

use Test::More 0.94;

plan tests => 367 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Class/MOP.pm',
    'Class/MOP/Class/Immutable/Trait.pm',
    'Class/MOP/Deprecated.pm',
    'Class/MOP/Instance.pm',
    'Class/MOP/Method.pm',
    'Class/MOP/Method/Generated.pm',
    'Class/MOP/Method/Meta.pm',
    'Class/MOP/MiniTrait.pm',
    'Class/MOP/Mixin.pm',
    'Class/MOP/Mixin/AttributeCore.pm',
    'Class/MOP/Mixin/HasMethods.pm',
    'Class/MOP/Mixin/HasOverloads.pm',
    'Class/MOP/Object.pm',
    'Class/MOP/Overload.pm',
    'Moose.pm',
    'Moose/Conflicts.pm',
    'Moose/Deprecated.pm',
    'Moose/Exception.pm',
    'Moose/Exception/AccessorMustReadWrite.pm',
    'Moose/Exception/AddParameterizableTypeTakesParameterizableType.pm',
    'Moose/Exception/AddRoleTakesAMooseMetaRoleInstance.pm',
    'Moose/Exception/AddRoleToARoleTakesAMooseMetaRole.pm',
    'Moose/Exception/ApplyTakesABlessedInstance.pm',
    'Moose/Exception/AttachToClassNeedsAClassMOPClassInstanceOrASubclass.pm',
    'Moose/Exception/AttributeConflictInRoles.pm',
    'Moose/Exception/AttributeConflictInSummation.pm',
    'Moose/Exception/AttributeExtensionIsNotSupportedInRoles.pm',
    'Moose/Exception/AttributeIsRequired.pm',
    'Moose/Exception/AttributeMustBeAnClassMOPMixinAttributeCoreOrSubclass.pm',
    'Moose/Exception/AttributeNamesDoNotMatch.pm',
    'Moose/Exception/AttributeValueIsNotAnObject.pm',
    'Moose/Exception/AttributeValueIsNotDefined.pm',
    'Moose/Exception/AutoDeRefNeedsArrayRefOrHashRef.pm',
    'Moose/Exception/BadOptionFormat.pm',
    'Moose/Exception/BothBuilderAndDefaultAreNotAllowed.pm',
    'Moose/Exception/BuilderDoesNotExist.pm',
    'Moose/Exception/BuilderMethodNotSupportedForAttribute.pm',
    'Moose/Exception/BuilderMethodNotSupportedForInlineAttribute.pm',
    'Moose/Exception/BuilderMustBeAMethodName.pm',
    'Moose/Exception/CallingMethodOnAnImmutableInstance.pm',
    'Moose/Exception/CallingReadOnlyMethodOnAnImmutableInstance.pm',
    'Moose/Exception/CanExtendOnlyClasses.pm',
    'Moose/Exception/CanOnlyConsumeRole.pm',
    'Moose/Exception/CanOnlyWrapBlessedCode.pm',
    'Moose/Exception/CanReblessOnlyIntoASubclass.pm',
    'Moose/Exception/CanReblessOnlyIntoASuperclass.pm',
    'Moose/Exception/CannotAddAdditionalTypeCoercionsToUnion.pm',
    'Moose/Exception/CannotAddAsAnAttributeToARole.pm',
    'Moose/Exception/CannotApplyBaseClassRolesToRole.pm',
    'Moose/Exception/CannotAssignValueToReadOnlyAccessor.pm',
    'Moose/Exception/CannotAugmentIfLocalMethodPresent.pm',
    'Moose/Exception/CannotAugmentNoSuperMethod.pm',
    'Moose/Exception/CannotAutoDerefWithoutIsa.pm',
    'Moose/Exception/CannotAutoDereferenceTypeConstraint.pm',
    'Moose/Exception/CannotCalculateNativeType.pm',
    'Moose/Exception/CannotCallAnAbstractBaseMethod.pm',
    'Moose/Exception/CannotCallAnAbstractMethod.pm',
    'Moose/Exception/CannotCoerceAWeakRef.pm',
    'Moose/Exception/CannotCoerceAttributeWhichHasNoCoercion.pm',
    'Moose/Exception/CannotCreateHigherOrderTypeWithoutATypeParameter.pm',
    'Moose/Exception/CannotCreateMethodAliasLocalMethodIsPresent.pm',
    'Moose/Exception/CannotCreateMethodAliasLocalMethodIsPresentInClass.pm',
    'Moose/Exception/CannotDelegateLocalMethodIsPresent.pm',
    'Moose/Exception/CannotDelegateWithoutIsa.pm',
    'Moose/Exception/CannotFindDelegateMetaclass.pm',
    'Moose/Exception/CannotFindType.pm',
    'Moose/Exception/CannotFindTypeGivenToMatchOnType.pm',
    'Moose/Exception/CannotFixMetaclassCompatibility.pm',
    'Moose/Exception/CannotGenerateInlineConstraint.pm',
    'Moose/Exception/CannotInitializeMooseMetaRoleComposite.pm',
    'Moose/Exception/CannotInlineTypeConstraintCheck.pm',
    'Moose/Exception/CannotLocatePackageInINC.pm',
    'Moose/Exception/CannotMakeMetaclassCompatible.pm',
    'Moose/Exception/CannotOverrideALocalMethod.pm',
    'Moose/Exception/CannotOverrideBodyOfMetaMethods.pm',
    'Moose/Exception/CannotOverrideLocalMethodIsPresent.pm',
    'Moose/Exception/CannotOverrideNoSuperMethod.pm',
    'Moose/Exception/CannotRegisterUnnamedTypeConstraint.pm',
    'Moose/Exception/CannotUseLazyBuildAndDefaultSimultaneously.pm',
    'Moose/Exception/CircularReferenceInAlso.pm',
    'Moose/Exception/ClassDoesNotHaveInitMeta.pm',
    'Moose/Exception/ClassDoesTheExcludedRole.pm',
    'Moose/Exception/ClassNamesDoNotMatch.pm',
    'Moose/Exception/CloneObjectExpectsAnInstanceOfMetaclass.pm',
    'Moose/Exception/CodeBlockMustBeACodeRef.pm',
    'Moose/Exception/CoercingWithoutCoercions.pm',
    'Moose/Exception/CoercionAlreadyExists.pm',
    'Moose/Exception/CoercionNeedsTypeConstraint.pm',
    'Moose/Exception/ConflictDetectedInCheckRoleExclusions.pm',
    'Moose/Exception/ConflictDetectedInCheckRoleExclusionsInToClass.pm',
    'Moose/Exception/ConstructClassInstanceTakesPackageName.pm',
    'Moose/Exception/CouldNotCreateMethod.pm',
    'Moose/Exception/CouldNotCreateWriter.pm',
    'Moose/Exception/CouldNotEvalConstructor.pm',
    'Moose/Exception/CouldNotEvalDestructor.pm',
    'Moose/Exception/CouldNotFindTypeConstraintToCoerceFrom.pm',
    'Moose/Exception/CouldNotGenerateInlineAttributeMethod.pm',
    'Moose/Exception/CouldNotLocateTypeConstraintForUnion.pm',
    'Moose/Exception/CouldNotParseType.pm',
    'Moose/Exception/CreateMOPClassTakesArrayRefOfAttributes.pm',
    'Moose/Exception/CreateMOPClassTakesArrayRefOfSuperclasses.pm',
    'Moose/Exception/CreateMOPClassTakesHashRefOfMethods.pm',
    'Moose/Exception/CreateTakesArrayRefOfRoles.pm',
    'Moose/Exception/CreateTakesHashRefOfAttributes.pm',
    'Moose/Exception/CreateTakesHashRefOfMethods.pm',
    'Moose/Exception/DefaultToMatchOnTypeMustBeCodeRef.pm',
    'Moose/Exception/DelegationToAClassWhichIsNotLoaded.pm',
    'Moose/Exception/DelegationToARoleWhichIsNotLoaded.pm',
    'Moose/Exception/DelegationToATypeWhichIsNotAClass.pm',
    'Moose/Exception/DoesRequiresRoleName.pm',
    'Moose/Exception/EnumCalledWithAnArrayRefAndAdditionalArgs.pm',
    'Moose/Exception/EnumValuesMustBeString.pm',
    'Moose/Exception/ExtendsMissingArgs.pm',
    'Moose/Exception/HandlesMustBeAHashRef.pm',
    'Moose/Exception/IllegalInheritedOptions.pm',
    'Moose/Exception/IllegalMethodTypeToAddMethodModifier.pm',
    'Moose/Exception/IncompatibleMetaclassOfSuperclass.pm',
    'Moose/Exception/InitMetaRequiresClass.pm',
    'Moose/Exception/InitializeTakesUnBlessedPackageName.pm',
    'Moose/Exception/InstanceBlessedIntoWrongClass.pm',
    'Moose/Exception/InstanceMustBeABlessedReference.pm',
    'Moose/Exception/InvalidArgPassedToMooseUtilMetaRole.pm',
    'Moose/Exception/InvalidArgumentToMethod.pm',
    'Moose/Exception/InvalidArgumentsToTraitAliases.pm',
    'Moose/Exception/InvalidBaseTypeGivenToCreateParameterizedTypeConstraint.pm',
    'Moose/Exception/InvalidHandleValue.pm',
    'Moose/Exception/InvalidHasProvidedInARole.pm',
    'Moose/Exception/InvalidNameForType.pm',
    'Moose/Exception/InvalidOverloadOperator.pm',
    'Moose/Exception/InvalidRoleApplication.pm',
    'Moose/Exception/InvalidTypeConstraint.pm',
    'Moose/Exception/InvalidTypeGivenToCreateParameterizedTypeConstraint.pm',
    'Moose/Exception/InvalidValueForIs.pm',
    'Moose/Exception/IsaDoesNotDoTheRole.pm',
    'Moose/Exception/IsaLacksDoesMethod.pm',
    'Moose/Exception/LazyAttributeNeedsADefault.pm',
    'Moose/Exception/Legacy.pm',
    'Moose/Exception/MOPAttributeNewNeedsAttributeName.pm',
    'Moose/Exception/MatchActionMustBeACodeRef.pm',
    'Moose/Exception/MessageParameterMustBeCodeRef.pm',
    'Moose/Exception/MetaclassIsAClassNotASubclassOfGivenMetaclass.pm',
    'Moose/Exception/MetaclassIsARoleNotASubclassOfGivenMetaclass.pm',
    'Moose/Exception/MetaclassIsNotASubclassOfGivenMetaclass.pm',
    'Moose/Exception/MetaclassMustBeASubclassOfMooseMetaClass.pm',
    'Moose/Exception/MetaclassMustBeASubclassOfMooseMetaRole.pm',
    'Moose/Exception/MetaclassMustBeDerivedFromClassMOPClass.pm',
    'Moose/Exception/MetaclassNotLoaded.pm',
    'Moose/Exception/MetaclassTypeIncompatible.pm',
    'Moose/Exception/MethodExpectedAMetaclassObject.pm',
    'Moose/Exception/MethodExpectsFewerArgs.pm',
    'Moose/Exception/MethodExpectsMoreArgs.pm',
    'Moose/Exception/MethodModifierNeedsMethodName.pm',
    'Moose/Exception/MethodNameConflictInRoles.pm',
    'Moose/Exception/MethodNameNotFoundInInheritanceHierarchy.pm',
    'Moose/Exception/MethodNameNotGiven.pm',
    'Moose/Exception/MustDefineAMethodName.pm',
    'Moose/Exception/MustDefineAnAttributeName.pm',
    'Moose/Exception/MustDefineAnOverloadOperator.pm',
    'Moose/Exception/MustHaveAtLeastOneValueToEnumerate.pm',
    'Moose/Exception/MustPassAHashOfOptions.pm',
    'Moose/Exception/MustPassAMooseMetaRoleInstanceOrSubclass.pm',
    'Moose/Exception/MustPassAPackageNameOrAnExistingClassMOPPackageInstance.pm',
    'Moose/Exception/MustPassEvenNumberOfArguments.pm',
    'Moose/Exception/MustPassEvenNumberOfAttributeOptions.pm',
    'Moose/Exception/MustProvideANameForTheAttribute.pm',
    'Moose/Exception/MustSpecifyAtleastOneMethod.pm',
    'Moose/Exception/MustSpecifyAtleastOneRole.pm',
    'Moose/Exception/MustSpecifyAtleastOneRoleToApplicant.pm',
    'Moose/Exception/MustSupplyAClassMOPAttributeInstance.pm',
    'Moose/Exception/MustSupplyADelegateToMethod.pm',
    'Moose/Exception/MustSupplyAMetaclass.pm',
    'Moose/Exception/MustSupplyAMooseMetaAttributeInstance.pm',
    'Moose/Exception/MustSupplyAnAccessorTypeToConstructWith.pm',
    'Moose/Exception/MustSupplyAnAttributeToConstructWith.pm',
    'Moose/Exception/MustSupplyArrayRefAsCurriedArguments.pm',
    'Moose/Exception/MustSupplyPackageNameAndName.pm',
    'Moose/Exception/NeedsTypeConstraintUnionForTypeCoercionUnion.pm',
    'Moose/Exception/NeitherAttributeNorAttributeNameIsGiven.pm',
    'Moose/Exception/NeitherClassNorClassNameIsGiven.pm',
    'Moose/Exception/NeitherRoleNorRoleNameIsGiven.pm',
    'Moose/Exception/NeitherTypeNorTypeNameIsGiven.pm',
    'Moose/Exception/NoAttributeFoundInSuperClass.pm',
    'Moose/Exception/NoBodyToInitializeInAnAbstractBaseClass.pm',
    'Moose/Exception/NoCasesMatched.pm',
    'Moose/Exception/NoConstraintCheckForTypeConstraint.pm',
    'Moose/Exception/NoDestructorClassSpecified.pm',
    'Moose/Exception/NoImmutableTraitSpecifiedForClass.pm',
    'Moose/Exception/NoParentGivenToSubtype.pm',
    'Moose/Exception/OnlyInstancesCanBeCloned.pm',
    'Moose/Exception/OperatorIsRequired.pm',
    'Moose/Exception/OverloadConflictInSummation.pm',
    'Moose/Exception/OverloadRequiresAMetaClass.pm',
    'Moose/Exception/OverloadRequiresAMetaMethod.pm',
    'Moose/Exception/OverloadRequiresAMetaOverload.pm',
    'Moose/Exception/OverloadRequiresAMethodNameOrCoderef.pm',
    'Moose/Exception/OverloadRequiresAnOperator.pm',
    'Moose/Exception/OverloadRequiresNamesForCoderef.pm',
    'Moose/Exception/OverrideConflictInComposition.pm',
    'Moose/Exception/OverrideConflictInSummation.pm',
    'Moose/Exception/PackageDoesNotUseMooseExporter.pm',
    'Moose/Exception/PackageNameAndNameParamsNotGivenToWrap.pm',
    'Moose/Exception/PackagesAndModulesAreNotCachable.pm',
    'Moose/Exception/ParameterIsNotSubtypeOfParent.pm',
    'Moose/Exception/ReferencesAreNotAllowedAsDefault.pm',
    'Moose/Exception/RequiredAttributeLacksInitialization.pm',
    'Moose/Exception/RequiredAttributeNeedsADefault.pm',
    'Moose/Exception/RequiredMethodsImportedByClass.pm',
    'Moose/Exception/RequiredMethodsNotImplementedByClass.pm',
    'Moose/Exception/Role/Attribute.pm',
    'Moose/Exception/Role/AttributeName.pm',
    'Moose/Exception/Role/Class.pm',
    'Moose/Exception/Role/EitherAttributeOrAttributeName.pm',
    'Moose/Exception/Role/Instance.pm',
    'Moose/Exception/Role/InstanceClass.pm',
    'Moose/Exception/Role/InvalidAttributeOptions.pm',
    'Moose/Exception/Role/Method.pm',
    'Moose/Exception/Role/ParamsHash.pm',
    'Moose/Exception/Role/Role.pm',
    'Moose/Exception/Role/RoleForCreate.pm',
    'Moose/Exception/Role/RoleForCreateMOPClass.pm',
    'Moose/Exception/Role/TypeConstraint.pm',
    'Moose/Exception/RoleDoesTheExcludedRole.pm',
    'Moose/Exception/RoleExclusionConflict.pm',
    'Moose/Exception/RoleNameRequired.pm',
    'Moose/Exception/RoleNameRequiredForMooseMetaRole.pm',
    'Moose/Exception/RolesDoNotSupportAugment.pm',
    'Moose/Exception/RolesDoNotSupportExtends.pm',
    'Moose/Exception/RolesDoNotSupportInner.pm',
    'Moose/Exception/RolesDoNotSupportRegexReferencesForMethodModifiers.pm',
    'Moose/Exception/RolesInCreateTakesAnArrayRef.pm',
    'Moose/Exception/RolesListMustBeInstancesOfMooseMetaRole.pm',
    'Moose/Exception/SingleParamsToNewMustBeHashRef.pm',
    'Moose/Exception/TriggerMustBeACodeRef.pm',
    'Moose/Exception/TypeConstraintCannotBeUsedForAParameterizableType.pm',
    'Moose/Exception/TypeConstraintIsAlreadyCreated.pm',
    'Moose/Exception/TypeParameterMustBeMooseMetaType.pm',
    'Moose/Exception/UnableToCanonicalizeHandles.pm',
    'Moose/Exception/UnableToCanonicalizeNonRolePackage.pm',
    'Moose/Exception/UnableToRecognizeDelegateMetaclass.pm',
    'Moose/Exception/UndefinedHashKeysPassedToMethod.pm',
    'Moose/Exception/UnionCalledWithAnArrayRefAndAdditionalArgs.pm',
    'Moose/Exception/UnionTakesAtleastTwoTypeNames.pm',
    'Moose/Exception/ValidationFailedForInlineTypeConstraint.pm',
    'Moose/Exception/ValidationFailedForTypeConstraint.pm',
    'Moose/Exception/WrapTakesACodeRefToBless.pm',
    'Moose/Exception/WrongTypeConstraintGiven.pm',
    'Moose/Exporter.pm',
    'Moose/Meta/Attribute/Native/Trait.pm',
    'Moose/Meta/Attribute/Native/Trait/Array.pm',
    'Moose/Meta/Attribute/Native/Trait/Bool.pm',
    'Moose/Meta/Attribute/Native/Trait/Code.pm',
    'Moose/Meta/Attribute/Native/Trait/Counter.pm',
    'Moose/Meta/Attribute/Native/Trait/Hash.pm',
    'Moose/Meta/Attribute/Native/Trait/Number.pm',
    'Moose/Meta/Attribute/Native/Trait/String.pm',
    'Moose/Meta/Class.pm',
    'Moose/Meta/Class/Immutable/Trait.pm',
    'Moose/Meta/Instance.pm',
    'Moose/Meta/Method.pm',
    'Moose/Meta/Method/Accessor.pm',
    'Moose/Meta/Method/Accessor/Native.pm',
    'Moose/Meta/Method/Accessor/Native/Array.pm',
    'Moose/Meta/Method/Accessor/Native/Array/Writer.pm',
    'Moose/Meta/Method/Accessor/Native/Array/accessor.pm',
    'Moose/Meta/Method/Accessor/Native/Array/clear.pm',
    'Moose/Meta/Method/Accessor/Native/Array/count.pm',
    'Moose/Meta/Method/Accessor/Native/Array/delete.pm',
    'Moose/Meta/Method/Accessor/Native/Array/elements.pm',
    'Moose/Meta/Method/Accessor/Native/Array/first.pm',
    'Moose/Meta/Method/Accessor/Native/Array/first_index.pm',
    'Moose/Meta/Method/Accessor/Native/Array/get.pm',
    'Moose/Meta/Method/Accessor/Native/Array/grep.pm',
    'Moose/Meta/Method/Accessor/Native/Array/insert.pm',
    'Moose/Meta/Method/Accessor/Native/Array/is_empty.pm',
    'Moose/Meta/Method/Accessor/Native/Array/join.pm',
    'Moose/Meta/Method/Accessor/Native/Array/map.pm',
    'Moose/Meta/Method/Accessor/Native/Array/natatime.pm',
    'Moose/Meta/Method/Accessor/Native/Array/pop.pm',
    'Moose/Meta/Method/Accessor/Native/Array/push.pm',
    'Moose/Meta/Method/Accessor/Native/Array/reduce.pm',
    'Moose/Meta/Method/Accessor/Native/Array/set.pm',
    'Moose/Meta/Method/Accessor/Native/Array/shallow_clone.pm',
    'Moose/Meta/Method/Accessor/Native/Array/shift.pm',
    'Moose/Meta/Method/Accessor/Native/Array/shuffle.pm',
    'Moose/Meta/Method/Accessor/Native/Array/sort.pm',
    'Moose/Meta/Method/Accessor/Native/Array/sort_in_place.pm',
    'Moose/Meta/Method/Accessor/Native/Array/splice.pm',
    'Moose/Meta/Method/Accessor/Native/Array/uniq.pm',
    'Moose/Meta/Method/Accessor/Native/Array/unshift.pm',
    'Moose/Meta/Method/Accessor/Native/Bool/not.pm',
    'Moose/Meta/Method/Accessor/Native/Bool/set.pm',
    'Moose/Meta/Method/Accessor/Native/Bool/toggle.pm',
    'Moose/Meta/Method/Accessor/Native/Bool/unset.pm',
    'Moose/Meta/Method/Accessor/Native/Code/execute.pm',
    'Moose/Meta/Method/Accessor/Native/Code/execute_method.pm',
    'Moose/Meta/Method/Accessor/Native/Collection.pm',
    'Moose/Meta/Method/Accessor/Native/Counter/Writer.pm',
    'Moose/Meta/Method/Accessor/Native/Counter/dec.pm',
    'Moose/Meta/Method/Accessor/Native/Counter/inc.pm',
    'Moose/Meta/Method/Accessor/Native/Counter/reset.pm',
    'Moose/Meta/Method/Accessor/Native/Counter/set.pm',
    'Moose/Meta/Method/Accessor/Native/Hash.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/Writer.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/accessor.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/clear.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/count.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/defined.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/delete.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/elements.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/exists.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/get.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/is_empty.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/keys.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/kv.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/set.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/shallow_clone.pm',
    'Moose/Meta/Method/Accessor/Native/Hash/values.pm',
    'Moose/Meta/Method/Accessor/Native/Number/abs.pm',
    'Moose/Meta/Method/Accessor/Native/Number/add.pm',
    'Moose/Meta/Method/Accessor/Native/Number/div.pm',
    'Moose/Meta/Method/Accessor/Native/Number/mod.pm',
    'Moose/Meta/Method/Accessor/Native/Number/mul.pm',
    'Moose/Meta/Method/Accessor/Native/Number/set.pm',
    'Moose/Meta/Method/Accessor/Native/Number/sub.pm',
    'Moose/Meta/Method/Accessor/Native/Reader.pm',
    'Moose/Meta/Method/Accessor/Native/String/append.pm',
    'Moose/Meta/Method/Accessor/Native/String/chomp.pm',
    'Moose/Meta/Method/Accessor/Native/String/chop.pm',
    'Moose/Meta/Method/Accessor/Native/String/clear.pm',
    'Moose/Meta/Method/Accessor/Native/String/inc.pm',
    'Moose/Meta/Method/Accessor/Native/String/length.pm',
    'Moose/Meta/Method/Accessor/Native/String/match.pm',
    'Moose/Meta/Method/Accessor/Native/String/prepend.pm',
    'Moose/Meta/Method/Accessor/Native/String/replace.pm',
    'Moose/Meta/Method/Accessor/Native/String/substr.pm',
    'Moose/Meta/Method/Accessor/Native/Writer.pm',
    'Moose/Meta/Method/Augmented.pm',
    'Moose/Meta/Method/Constructor.pm',
    'Moose/Meta/Method/Delegation.pm',
    'Moose/Meta/Method/Destructor.pm',
    'Moose/Meta/Method/Meta.pm',
    'Moose/Meta/Method/Overridden.pm',
    'Moose/Meta/Object/Trait.pm',
    'Moose/Meta/Role.pm',
    'Moose/Meta/Role/Application.pm',
    'Moose/Meta/Role/Application/RoleSummation.pm',
    'Moose/Meta/Role/Application/ToClass.pm',
    'Moose/Meta/Role/Application/ToInstance.pm',
    'Moose/Meta/Role/Application/ToRole.pm',
    'Moose/Meta/Role/Composite.pm',
    'Moose/Meta/Role/Method.pm',
    'Moose/Meta/Role/Method/Conflicting.pm',
    'Moose/Meta/Role/Method/Required.pm',
    'Moose/Meta/TypeCoercion.pm',
    'Moose/Meta/TypeCoercion/Union.pm',
    'Moose/Meta/TypeConstraint.pm',
    'Moose/Meta/TypeConstraint/Registry.pm',
    'Moose/Object.pm',
    'Moose/Role.pm',
    'Moose/Util.pm',
    'Moose/Util/MetaRole.pm',
    'Moose/Util/TypeConstraints.pm',
    'Moose/Util/TypeConstraints/Builtins.pm',
    'Test/Moose.pm',
    'metaclass.pm',
    'oose.pm'
);

my @scripts = (
    'bin/moose-outdated'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    @switches = (@switches, split(' ', $1)) if $1;

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', explain(\@warnings) if $ENV{AUTHOR_TESTING};

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
